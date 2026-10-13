import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../data/posters_repository.dart';
import '../model/customer.dart';
import '../model/poster.dart';
import 'poster_detail_page.dart';

import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../dishes/ui/dish_detail_page.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../shared/utils/display_names.dart';
import 'band_page.dart';
import '../../letters/ui/letter_detail_page.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../mementos/data/mementos_index.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../shared/data/unlocked_store.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/json_loader.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../mementos/ui/mementos_detail_page.dart';

/// What the Requirements chips need in order to be more than raw slugs.
class _RequirementLinks {
  final Map<String, String> facilityNames;
  final Map<String, String> letterNames;
  final Map<String, String> customerNames;
  final Map<String, String> flowerNames;

  /// Keyed by the raw `requirements.recipes` value, which is a display name.
  final Map<String, Dish> dishesByRequirement;

  const _RequirementLinks({
    required this.facilityNames,
    required this.letterNames,
    required this.customerNames,
    required this.flowerNames,
    required this.dishesByRequirement,
  });
}

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final store = UnlockedStore.instance;

  static const String _bucketCustomers = 'customers';
  static const String _bucketDish = 'dish';
  static const String _bucketLetter = 'letter';
  static const String _bucketFacility = 'facility';
  static const String _bucketMementoCollected = 'memento_collected';

  Customer get customer => widget.customer;

  /// memento id -> the indexed entry, when the memento is in MementosIndex.
  late final Future<Map<String, MementoEntry>> _mementoEntries;

  /// Display names and canonical ids for everything the Requirements block
  /// links to. Null until the lookups land; the chips render from the raw
  /// values until then, so the section never waits on a spinner.
  _RequirementLinks? _links;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);
    _mementoEntries = _resolveMementoEntries();
    _resolveRequirementLinks();

    // FishNames.nameFor is a synchronous lookup, so the map has to be warm
    // before the booth section builds. It falls back to prettifying the id,
    // so an in-flight or failed load degrades to "Hermit Crab" rather than
    // breaking the row.
    if (customer.boothOwner != null) {
      FishNames.instance.load().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
  }

  /// Resolves the requirement ids this customer actually has.
  ///
  /// Two things come out of it. A chip gets the entity's real name instead of
  /// the raw slug ('Halloween Streamers', not 'halloween_streamers'), and a
  /// chip whose id resolves to nothing is left untappable rather than opening
  /// a page that reads "Facility not found" or silently doing nothing.
  ///
  /// Recipes are the odd one out: `requirements.recipes` holds display names
  /// ('Adzuki Bean Dumpling'), while the dish bucket is keyed by dish id, so
  /// the chip has to carry the resolved Dish to know whether it is owned.
  Future<void> _resolveRequirementLinks() async {
    final r = customer.requirements;
    if (r == null) return;

    final facilityNames = <String, String>{};
    final letterNames = <String, String>{};
    final customerNames = <String, String>{};
    final flowerNames = <String, String>{};
    final dishes = <String, Dish>{};

    Future<void> guard(Future<void> Function() body) async {
      try {
        await body();
      } catch (_) {
        // A repository that fails to load leaves its chips as plain text
        // rather than taking the whole page down.
      }
    }

    if (r.facilities.isNotEmpty) {
      await guard(() async {
        for (final f in await FacilitiesRepository.instance.all()) {
          if (r.facilities.contains(f.id)) facilityNames[f.id] = f.name;
        }
      });
    }
    if (r.letters.isNotEmpty) {
      await guard(() async {
        for (final l in await LettersRepository.instance.all()) {
          if (r.letters.contains(l.id)) letterNames[l.id] = l.name;
        }
      });
    }
    if (r.customers.isNotEmpty) {
      await guard(() async {
        for (final c in await CustomersRepository.instance.all()) {
          if (r.customers.contains(c.id)) customerNames[c.id] = c.name;
        }
      });
    }
    if (r.flowers.isNotEmpty) {
      // Eight of the nine flower ids prettify to their real name; 'clover' is
      // "Four Leaf Clover", and nine customers ask for it.
      await guard(() async {
        final raw = await JsonLoader.load('assets/data/flowers.json');
        for (final e in (raw as List<dynamic>).cast<Map<String, dynamic>>()) {
          final id = e['id'] as String?;
          final name = e['name'] as String?;
          if (id != null && name != null && r.flowers.contains(id)) {
            flowerNames[id] = name;
          }
        }
      });
    }
    if (r.recipes.isNotEmpty) {
      await guard(() async {
        for (final raw in r.recipes) {
          final dish = await DishesRepository.instance.resolve(raw.toString());
          if (dish != null) dishes[raw.toString()] = dish;
        }
      });
    }

    if (!mounted) return;
    setState(() {
      _links = _RequirementLinks(
        facilityNames: facilityNames,
        letterNames: letterNames,
        customerNames: customerNames,
        flowerNames: flowerNames,
        dishesByRequirement: dishes,
      );
    });
  }

  Future<Map<String, MementoEntry>> _resolveMementoEntries() async {
    if (customer.mementos.isEmpty) return <String, MementoEntry>{};

    List<MementoEntry> all = const <MementoEntry>[];
    try {
      all = await MementosIndex.instance.all();
    } catch (_) {
      // Fall back to derived keys below rather than losing the section.
    }

    final byId = <String, MementoEntry>{for (final e in all) e.id: e};

    final out = <String, MementoEntry>{};
    for (final m in customer.mementos) {
      final entry = byId[m.id];
      if (entry != null) out[m.id] = entry;
    }
    return out;
  }

  /// The UnlockedStore key for one of this customer's mementos, or null when
  /// the memento is not in MementosIndex.
  ///
  /// mementos.json is the single source of truth for mementos; the array
  /// embedded in a customer is the same collectibles, rendered here as a
  /// convenience. Deriving a key for an unindexed memento would let the player
  /// check something the completion percentage does not count, so mementos the
  /// index does not know simply have no checkbox.
  String? _mementoKey(String mementoId, Map<String, MementoEntry> entries) =>
      entries[mementoId]?.key;

  bool get _isCustomerUnlocked =>
      store.isUnlocked(_bucketCustomers, customer.id);

  Future<void> _setCustomerUnlocked(bool v) async {
    await store.setUnlocked(_bucketCustomers, customer.id, v);
    if (mounted) setState(() {});
  }


  Future<void> _openCustomerById(BuildContext context, String id) async {
    final found = await CustomersRepository.instance.byId(id);
    if (!context.mounted || found == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: found),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openPosterById(BuildContext context, String posterId) async {
    final Poster? p = await PostersRepository.instance.byId(posterId);
    if (!context.mounted || p == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosterDetailPage(posterId: posterId),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = customer.requirements;

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unlocked'),
            value: _isCustomerUnlocked,
            onChanged: (v) {
              if (v == null) return;
              _setCustomerUnlocked(v);
            },
          ),

          Text(customer.customerDescription),

          const SizedBox(height: 16),
          if (customer.livesIn != null)
            _section('Lives In', Text(customer.livesIn!)),
          if (customer.appearanceWeight != null)
            _section(
              'Appearance Weight',
              Text(customer.appearanceWeight.toString()),
            ),

          if (customer.boothOwner != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Booth Owner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _boothOwnerSection(customer.boothOwner!),
          ],

          if (customer.performer != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Performer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _performerSection(context, customer.performer!),
          ],

          if (r != null && r.hasAny) ...[
            const SizedBox(height: 24),
            const Text(
              'Requirements to invite customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            if (r.requiredStars != null)
              _section('Rating', Text(r.requiredStars.toString())),

            if (r.recipes.isNotEmpty)
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Required Recipes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.recipes.map((id) {
                  // requirements.recipes holds display names, the dish bucket
                  // holds dish ids, so the fill only lights up once the name
                  // has been resolved to its Dish.
                  final raw = id.toString();
                  final dish = _links?.dishesByRequirement[raw];
                  final owned = dish != null &&
                      store.isUnlocked(_bucketDish, dish.id);
                  return EntityChip(
                  label: dish?.name ?? (raw.isEmpty
                      ? raw
                      : '${raw[0].toUpperCase()}${raw.substring(1)}'),
                  checked: owned,
                  onTap: () async {
                    await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DishDetailPage(dishId: dish?.id ?? raw),
                    ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
                  );
                }).toList(),
                ),
              ],
              ),

            _simpleLinks(
              context: context,
              title: 'Required Facilities',
              ids: r.facilities,
              isOwned: (id) =>
                  store.isUnlocked(_bucketFacility, id.toString()),
              names: _links?.facilityNames,
              onTap: (id) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FacilityDetailPage(facilityId: id.toString()),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            // Flowers are grown in the Vegetable Garden and are not facilities,
            // so they get their own section and no tap target: there is no
            // flower detail page to navigate to. They previously sat in
            // requirements.facilities and rendered as facility chips that led
            // to a FacilityDetailPage which could never resolve them.
            _simpleLinks(
              context: context,
              title: 'Required Flowers',
              ids: r.flowers,
              isOwned: (_) => false,
              names: _links?.flowerNames,
            ),

            _simpleLinks(
              context: context,
              title: 'Required Letters',
              ids: r.letters,
              isOwned: (id) => store.isUnlocked(_bucketLetter, id.toString()),
              names: _links?.letterNames,
              onTap: (id) async {
                final Letter? letter =
                    await LettersRepository.instance.byId(id.toString());
                if (!mounted || letter == null) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LetterDetailPage(letter: letter),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            _simpleLinks(
              context: context,
              title: 'Prerequisite Customers',
              ids: r.customers,
              isOwned: (id) =>
                  store.isUnlocked(_bucketCustomers, id.toString()),
              names: _links?.customerNames,
              onTap: (id) => _openCustomerById(context, id.toString()),
            ),
          ],

          if (customer.mementos.isNotEmpty) ...[
            const SizedBox(height: 24),
            FutureBuilder<Map<String, MementoEntry>>(
              future: _mementoEntries,
              builder: (context, snap) {
                final entries =
                    snap.data ?? const <String, MementoEntry>{};

                final keys = customer.mementos
                    .map((m) => _mementoKey(m.id, entries))
                    .whereType<String>()
                    .toList();
                final collectedCount = keys
                    .where((k) => store.isUnlocked(_bucketMementoCollected, k))
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mementos',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('$collectedCount/${keys.length}'),
                        CheckAllButton(
                          bucket: _bucketMementoCollected,
                          ids: keys,
                          groupLabel: "${customer.name}'s mementos",
                          onApplied: (_) {
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                    // A chip per memento used to show the name and nothing
                    // else, so reading what you actually have to do meant
                    // opening each memento and coming back — six taps for a
                    // customer with three. The requirement and the star value
                    // are already loaded in `entries[m.id]`, so they are shown
                    // inline instead.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: customer.mementos.map((m) {
                        final entry = entries[m.id];
                        final key = _mementoKey(m.id, entries);
                        final collected = key != null &&
                            store.isUnlocked(_bucketMementoCollected, key);

                        // Only mementos present in MementosIndex have a
                        // detail page to open and a key to track.
                        VoidCallback? openDetail;
                        ValueChanged<bool>? onCheckChanged;
                        if (entry != null) {
                          final target = entry;
                          final storeKey = target.key;

                          openDetail = () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MementoDetailPage(memento: target),
                              ),
                            );
                            if (mounted) setState(() {});
                          };

                          onCheckChanged = (v) async {
                            await store.setUnlocked(
                                _bucketMementoCollected, storeKey, v);
                            if (mounted) setState(() {});
                          };
                        }

                        final requirement = entry?.requirement.trim() ?? '';
                        final stars = entry?.earnedStars ?? 0;

                        return InkWell(
                          onTap: openDetail,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (onCheckChanged != null)
                                  Checkbox(
                                    value: collected,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) =>
                                        onCheckChanged!(v ?? false),
                                  )
                                else
                                  const SizedBox(width: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      if (requirement.isNotEmpty)
                                        Text(
                                          requirement,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                if (stars > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      '+$stars★',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _boothOwnerSection(BoothOwnerInfo b) {
    final lines = <Widget>[];

    if (b.timeRange == null) {
      lines.add(_section('Time Range', const Text('Any Time')));
    } else {
      lines.add(_section(
        'Time Range',
        Text('${b.timeRange!.start} to ${b.timeRange!.end}'),
      ));
    }

    if (b.stayDurationMinutes != null) {
      lines.add(_section(
        'Stay Duration',
        Text(
          '${b.stayDurationMinutes!.min} min to ${b.stayDurationMinutes!.max} min',
        ),
      ));
    }

    if (b.requiredFishIds.isNotEmpty) {
      // Booth owners reference fish by id; the readable name lives in
      // fish.json. This printed raw slugs like "hermit_crab" before.
      lines.add(_section(
        'Required Fish',
        Text(b.requiredFishIds.map(FishNames.instance.nameFor).join(', ')),
      ));
    }

    if (b.customerDrop != null) {
      lines.add(_section(
        'Customer Drop',
        Text(
          '${b.customerDrop!.currency}: ${b.customerDrop!.min} ~ ${b.customerDrop!.max}',
        ),
      ));
    }

    if (b.incomeEvery5Min.isNotEmpty) {
      lines.add(const SizedBox(height: 8));
      lines.add(const Text(
        'Income every 5 min',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      for (final r in b.incomeEvery5Min) {
        final pct = (r.chance * 100).toStringAsFixed(0);
        lines.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              '$pct% chance to get ${prettyCurrency(r.currency)} ${r.amount}'),
        ));
      }
    }

    if (b.appearanceRatesByFish.isNotEmpty) {
      lines.add(const SizedBox(height: 8));
      lines.add(const Text(
        'Appearance probability',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('06:00-12:00 / 12:00-19:00 / 19:00-06:00'),
      ));
      for (final row in b.appearanceRatesByFish) {
        lines.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${row.fishId}: '
            '${row.morning?.toStringAsFixed(2) ?? '-'} / '
            '${row.afternoon?.toStringAsFixed(2) ?? '-'} / '
            '${row.night?.toStringAsFixed(2) ?? '-'}',
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _performerSection(BuildContext context, PerformerInfo p) {
    final lines = <Widget>[];

    if (p.band != null && p.band!.trim().isNotEmpty) {
      // The band was plain text, which was a dead end: no way to see the
      // other members. Opens the band's roster instead.
      lines.add(_section(
        'Band',
        Align(
          alignment: Alignment.centerLeft,
          child: EntityChip(
            label: p.band!,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BandPage(band: p.band!)),
              );
              if (!mounted) return;
              setState(() {});
            },
          ),
        ),
      ));
    }

    if (p.showDurationMinutes != null) {
      lines.add(_section('Show Duration', Text('${p.showDurationMinutes} mins')));
    }

    if (p.callbackRequirementHours != null) {
      lines.add(_section('Callback Requirement', Text('${p.callbackRequirementHours} hours')));
    }

    lines.add(AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final reached =
            store.isUnlocked(ProgressTypes.performerCallback, customer.id);
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Callback reached'),
          value: reached,
          onChanged: (v) => store.setUnlocked(
            ProgressTypes.performerCallback,
            customer.id,
            v ?? false,
          ),
        );
      },
    ));

    if (p.baseEarnings != null) {
      lines.add(_section(
        'Base Earnings',
        Text('${prettyCurrency(p.baseEarnings!.currency)} '
            '+${p.baseEarnings!.amountPerMinute}/min'),
      ));
    }

    if (p.fansCustomerIds.isNotEmpty) {
      lines.add(const Text('Fans', style: TextStyle(fontWeight: FontWeight.bold)));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.fansCustomerIds.map((id) {
          return EntityChip(
            label: id,
            onTap: () => _openCustomerById(context, id),
          );
        }).toList(),
      ));
      lines.add(const SizedBox(height: 12));
    }

    if (p.canInviteThis.isNotEmpty) {
      lines.add(const Text(
        'Performers who can invite this performer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.canInviteThis.map((e) {
          return EntityChip(
            label: '${e.performerId} (${e.chancePercent.toStringAsFixed(2)}%)',
            onTap: () => _openCustomerById(context, e.performerId),
          );
        }).toList(),
      ));
      lines.add(const SizedBox(height: 12));
    }

    if (p.canBeInvitedBy.isNotEmpty) {
      lines.add(const Text(
        'Performers who can be invited by this performer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.canBeInvitedBy.map((e) {
          return EntityChip(
            label: '${e.performerId} (${e.chancePercent.toStringAsFixed(2)}%)',
            onTap: () => _openCustomerById(context, e.performerId),
          );
        }).toList(),
      ));
    }

    if (p.posterIds.isNotEmpty) {
      lines.add(const SizedBox(height: 12));
      lines.add(const Text(
        'Poster Featured',
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lines.add(const SizedBox(height: 6));
      lines.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: p.posterIds.map((pid) {
          return EntityChip(
            label: pid,
            onTap: () => _openPosterById(context, pid),
          );
        }).toList(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
        const SizedBox(height: 12),
      ],
    );
  }

  /// A row of requirement chips.
  ///
  /// [names] maps id -> display name. An id missing from it once the lookups
  /// have finished is one nothing can resolve: the chip keeps its prettified
  /// text but loses its tap, because the page behind it does not exist. Pass
  /// null for a section that never links anywhere (flowers).
  Widget _simpleLinks({
    required BuildContext context,
    required String title,
    required List ids,
    required bool Function(dynamic id) isOwned,
    Map<String, String>? names,
    Future<void> Function(dynamic id)? onTap,
  }) {
    if (ids.isEmpty) return const SizedBox.shrink();

    final resolved = _links != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ids.map((id) {
            final key = id.toString();
            final name = names?[key];
            final links = onTap != null && (!resolved || name != null);
            return EntityChip(
              label: name ?? prettyId(key),
              // The same thing is ticked off on its own page; saying so here
              // saves going to look.
              checked: isOwned(id),
              onTap: links ? () => onTap(id) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
