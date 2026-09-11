import 'package:flutter/foundation.dart';

import '../../aromatic_acorn/data/aromatic_acorn_data.dart';
import '../../battle_pass/data/battle_pass_repository.dart';
import '../../courtyard/data/courtyard_repository.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/data/posters_repository.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../letters/data/letters_repository.dart';
import '../../mementos/data/mementos_index.dart';
import '../../movies/data/movies_repository.dart';
import '../../pets/data/pets_repository.dart';
import '../../shared/data/unlocked_store.dart';
import '../../staff/data/staff_repository.dart';
import 'progress_types.dart';

/// One (bucket, ids) slice of a category.
///
/// A category usually has exactly one part; pets have four (owned / mature /
/// rooms / photo tasks) and the battle pass has one part per reward track.
@immutable
class CompletionPart {
  const CompletionPart(this.bucket, this.ids, {this.enabled});

  /// UnlockedStore type key.
  final String bucket;

  /// Every trackable id in this slice.
  final List<String> ids;

  /// When set, the slice only counts (numerator AND denominator) while this
  /// returns true. Used for the battle pass Super track, which only exists for
  /// players who bought that pass's premium tier.
  final bool Function(UnlockedStore store)? enabled;

  bool isEnabled(UnlockedStore store) => enabled == null || enabled!(store);
}

/// A row on the progress page: one collectible set, e.g. "Letters".
@immutable
class CompletionCategory {
  const CompletionCategory({
    required this.key,
    required this.label,
    required this.parts,
    this.countsTowardTotal = true,
    this.subgroups = const <CompletionCategory>[],
    this.note,
    this.error,
  });

  /// Stable id, also used by the UI to pick the page to open on tap.
  final String key;

  final String label;

  final List<CompletionPart> parts;

  /// False for sets that are a subset of another category (booth owners are
  /// customers; memento source subgroups are slices of Mementos), so the
  /// overall percentage does not count them twice.
  final bool countsTowardTotal;

  /// Optional breakdown *inside* this category. Subgroups partition this
  /// category's own ids, so they always have countsTowardTotal == false.
  final List<CompletionCategory> subgroups;

  /// Small explanatory line under the row.
  final String? note;

  /// Non-null when this category's data failed to load. The row is shown as
  /// unavailable instead of breaking the whole page.
  final String? error;

  bool get isAvailable => error == null;

  int total(UnlockedStore store) {
    var n = 0;
    for (final p in parts) {
      if (!p.isEnabled(store)) continue;
      n += p.ids.length;
    }
    return n;
  }

  int collected(UnlockedStore store) {
    var n = 0;
    for (final p in parts) {
      if (!p.isEnabled(store)) continue;
      for (final id in p.ids) {
        if (store.isUnlocked(p.bucket, id)) n++;
      }
    }
    return n;
  }

  /// 0.0 .. 1.0. An empty or unavailable category reads as 0.
  double fraction(UnlockedStore store) {
    final t = total(store);
    if (t == 0) return 0;
    return collected(store) / t;
  }
}

/// The whole trackable catalogue, loaded once.
@immutable
class CompletionData {
  const CompletionData(this.categories);

  final List<CompletionCategory> categories;

  Iterable<CompletionCategory> get counting =>
      categories.where((c) => c.isAvailable && c.countsTowardTotal);

  int overallTotal(UnlockedStore store) {
    var n = 0;
    for (final c in counting) {
      n += c.total(store);
    }
    return n;
  }

  int overallCollected(UnlockedStore store) {
    var n = 0;
    for (final c in counting) {
      n += c.collected(store);
    }
    return n;
  }

  /// Weighting: every individual collectible counts exactly once and equally,
  /// so the big sets (facilities, courtyard, customers) honestly dominate.
  double overallFraction(UnlockedStore store) {
    final t = overallTotal(store);
    if (t == 0) return 0;
    return overallCollected(store) / t;
  }
}

/// Builds the catalogue of everything that can be collected, and how many of
/// each the player has checked off.
///
/// Totals come from the shipped JSON via the existing repositories and are
/// computed exactly once per app run (they cannot change at runtime). Only the
/// cheap counting pass re-runs when `UnlockedStore` notifies.
class CompletionService {
  CompletionService._();
  static final CompletionService instance = CompletionService._();

  Future<CompletionData>? _future;

  Future<CompletionData> load({bool forceReload = false}) {
    if (forceReload) _future = null;
    return _future ??= _build();
  }

  Future<CompletionData> _build() async {
    final store = UnlockedStore.instance;
    if (!store.isInitialized) {
      await store.init();
    }
    // Buckets outside UnlockedStore._defaultTypes have to be registered before
    // their saved ids are readable.
    for (final type in ProgressTypes.registerOnStartup) {
      await store.registerType(type);
    }

    final categories = <CompletionCategory>[
      await _guard('customers', 'Customers', _customers),
      await _mementosCategory(),
      await _guard('recipes', 'Recipes', _recipes),
      await _guard('letters', 'Letters', _letters),
      await _guard('facilities', 'Facilities', _facilities),
      await _guard('courtyard', 'Courtyard', _courtyard),
      await _guard('pets', 'Pets', _pets),
      await _guard('staff', 'Staff', _staff),
      await _guard('movies', 'Movie Acts', _movies),
      await _guard('posters', 'Posters', _posters),
      await _guard('battle_pass', 'Battle Pass', _battlePass),
      await _guard('aromatic_acorn', 'Aromatic Acorn Judging', _acorn),
      await _guard(
        'booth_owners',
        'Booth Owners',
        _boothOwners,
        countsTowardTotal: false,
        note: 'Booth owners are customers, so they are already counted above.',
      ),
    ];

    return CompletionData(categories);
  }

  Future<CompletionCategory> _guard(
    String key,
    String label,
    Future<List<CompletionPart>> Function() build, {
    bool countsTowardTotal = true,
    String? note,
  }) async {
    try {
      final parts = await build();
      return CompletionCategory(
        key: key,
        label: label,
        parts: parts,
        countsTowardTotal: countsTowardTotal,
        note: note,
      );
    } catch (e) {
      return CompletionCategory(
        key: key,
        label: label,
        parts: const <CompletionPart>[],
        countsTowardTotal: countsTowardTotal,
        note: note,
        error: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------- builders

  Future<List<CompletionPart>> _customers() async {
    final all = await CustomersRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.customers,
        all.map((c) => c.id).toList(growable: false),
      ),
    ];
  }

  Future<List<CompletionPart>> _boothOwners() async {
    final all = await CustomersRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.customers,
        all
            .where((c) => c.boothOwner != null)
            .map((c) => c.id)
            .toList(growable: false),
      ),
    ];
  }

  /// Mementos are counted from `assets/data/mementos.json` ONLY, via
  /// MementosIndex.
  ///
  /// DO NOT also add the `mementos` array embedded in each customer inside
  /// customers.json: those embedded entries are the same collectibles with the
  /// same ids (123 of the 1184 mementos are customer-linked), not extra ones.
  /// Summing both sets would double count them and the percentage would be
  /// permanently wrong. The customer page renders its embedded array purely as
  /// a display/link.
  ///
  /// The list is deduplicated by memento `id` anyway, defensively: this data
  /// has drifted once already, and a duplicate id must never inflate the
  /// denominator.
  Future<CompletionCategory> _mementosCategory() async {
    try {
      final entries = await MementosIndex.instance.all();

      final seenIds = <String>{};
      final unique = <MementoEntry>[];
      for (final e in entries) {
        if (seenIds.add(e.id)) unique.add(e);
      }

      // Mementos are a first-class set, not a customer sub-collection: only
      // 123 of them belong to a customer at all. The useful breakdown is by
      // where you grind them out, i.e. `source`.
      final bySource = <String, List<String>>{};
      for (final e in unique) {
        final label = prettyMementoSource(e.source);
        (bySource[label] ??= <String>[]).add(e.key);
      }

      final sourceLabels = bySource.keys.toList()
        ..sort((a, b) {
          final bySize = bySource[b]!.length.compareTo(bySource[a]!.length);
          return bySize != 0 ? bySize : a.compareTo(b);
        });

      return CompletionCategory(
        key: 'mementos',
        label: 'Mementos',
        parts: <CompletionPart>[
          CompletionPart(
            ProgressTypes.mementoCollected,
            unique.map((e) => e.key).toList(growable: false),
          ),
        ],
        subgroups: <CompletionCategory>[
          for (final label in sourceLabels)
            CompletionCategory(
              key: 'mementos:$label',
              label: label,
              parts: <CompletionPart>[
                CompletionPart(ProgressTypes.mementoCollected, bySource[label]!),
              ],
              countsTowardTotal: false,
            ),
        ],
      );
    } catch (e) {
      return CompletionCategory(
        key: 'mementos',
        label: 'Mementos',
        parts: const <CompletionPart>[],
        error: e.toString(),
      );
    }
  }

  /// 'signature_store' -> 'Signature Store'; null/empty -> 'Other'.
  static String prettyMementoSource(String? source) {
    final s = (source ?? '').trim();
    if (s.isEmpty) return 'Other';
    return s
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<List<CompletionPart>> _recipes() async {
    final all = await DishesRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.dish,
        all.map((d) => d.id).toList(growable: false),
      ),
    ];
  }

  Future<List<CompletionPart>> _letters() async {
    final all = await LettersRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.letter,
        all.map((l) => l.id).toList(growable: false),
      ),
    ];
  }

  /// The scenes FacilitiesPage actually shows. The courtyard, concert and
  /// pet-yard shards are excluded here: all three are tracked in their own
  /// bucket by CourtyardPage (see [_courtyard]) and would otherwise be double
  /// counted.
  static const List<FacilityArea> _facilityScenes = <FacilityArea>[
    FacilityArea.restaurant,
    FacilityArea.kitchen,
    FacilityArea.garden,
    FacilityArea.buffet,
    FacilityArea.takeout,
    FacilityArea.terrace,
  ];

  Future<List<CompletionPart>> _facilities() async {
    final repo = FacilitiesRepository.instance;
    final ids = <String>{};
    for (final area in _facilityScenes) {
      for (final f in await repo.byArea(area)) {
        ids.add(f.id);
      }
    }
    return <CompletionPart>[
      CompletionPart(ProgressTypes.facility, ids.toList(growable: false)),
    ];
  }

  /// The courtyard, the concert stage and the pet yard.
  ///
  /// All three are scenes of the Courtyard page and share the one bucket, so
  /// this counts [CourtyardRepository.allFacilities] rather than the courtyard
  /// shard alone. The concert and pet shards used to be in neither this
  /// category nor [_facilities], which left 535 facilities uncountable.
  Future<List<CompletionPart>> _courtyard() async {
    final repo = CourtyardRepository.instance;
    await repo.ensureLoaded();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.courtyardFacility,
        repo.allFacilities.map((f) => f.id).toList(growable: false),
      ),
    ];
  }

  Future<List<CompletionPart>> _pets() async {
    final data = await PetsRepository.instance.load();
    final petIds = data.pets.map((p) => p.id).toList(growable: false);
    return <CompletionPart>[
      CompletionPart(ProgressTypes.petOwned, petIds),
      CompletionPart(ProgressTypes.petMature, petIds),
      CompletionPart(
        ProgressTypes.petRoom,
        data.rooms.map((r) => r.id).toList(growable: false),
      ),
      CompletionPart(
        ProgressTypes.petPhotoTask,
        data.photoTasks.map((t) => t.id).toList(growable: false),
      ),
    ];
  }

  Future<List<CompletionPart>> _staff() async {
    final all = await StaffRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.staffUnlocked,
        all.map((s) => s.id).toList(growable: false),
      ),
    ];
  }

  Future<List<CompletionPart>> _movies() async {
    final all = await MoviesRepository.instance.all();
    final keys = <String>[];
    for (final m in all) {
      keys.addAll(m.allActKeys());
    }
    return <CompletionPart>[
      CompletionPart(ProgressTypes.movieAct, keys),
    ];
  }

  Future<List<CompletionPart>> _posters() async {
    final all = await PostersRepository.instance.all();
    return <CompletionPart>[
      CompletionPart(
        ProgressTypes.poster,
        all.map((p) => p.id).toList(growable: false),
      ),
    ];
  }

  /// Claim key shape must match BattlePassDetailPage._claimKey.
  static String battlePassClaimKey({
    required String passId,
    required String phaseId,
    required String track,
    required int exp,
  }) =>
      'bp:$passId:$phaseId:$track:$exp';

  Future<List<CompletionPart>> _battlePass() async {
    final repo = BattlePassRepository.instance;
    final parts = <CompletionPart>[];

    for (final passId in repo.availableIds) {
      try {
        final pass = await repo.byId(passId);

        final normalKeys = <String>[];
        final superKeys = <String>[];
        for (final phase in pass.phases) {
          for (final tier in phase.tiers) {
            normalKeys.add(battlePassClaimKey(
              passId: pass.id,
              phaseId: phase.id,
              track: 'normal',
              exp: tier.exp,
            ));
            superKeys.add(battlePassClaimKey(
              passId: pass.id,
              phaseId: phase.id,
              track: 'super',
              exp: tier.exp,
            ));
          }
        }

        parts.add(CompletionPart(ProgressTypes.battlePassClaimed, normalKeys));
        // The Super track only exists once you own that pass's premium tier,
        // so it only joins the denominator when you do.
        parts.add(
          CompletionPart(
            ProgressTypes.battlePassClaimed,
            superKeys,
            enabled: (store) =>
                store.isUnlocked(ProgressTypes.battlePassPremium, pass.id),
          ),
        );
      } catch (_) {
        // A single unreadable pass must not take the others down.
      }
    }

    return parts;
  }

  /// Id shapes must match AromaticAcornProgress._reqId / _taskId.
  static String acornRequirementId(String stageId, int index) =>
      'stage:$stageId:req:$index';

  static String acornTaskId(String stageId, int index) =>
      'stage:$stageId:task:$index';

  Future<List<CompletionPart>> _acorn() async {
    final ids = <String>[];
    for (final stage in AromaticAcornData.stages) {
      for (var i = 0; i < stage.requirements.length; i++) {
        ids.add(acornRequirementId(stage.id, i));
      }
      for (var i = 0; i < stage.tasks.length; i++) {
        ids.add(acornTaskId(stage.id, i));
      }
    }
    return <CompletionPart>[
      CompletionPart(ProgressTypes.acorn, ids),
    ];
  }
}
