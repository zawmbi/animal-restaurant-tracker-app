import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/json_loader.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';
import '../../shared/widgets/search_field.dart';

class RedemptionCode {
  final String code;
  final DateTime validFrom;
  final DateTime validUntil;
  final String reason;
  // The gift's id. Despite the name it is not always a memento — read
  // [giftKind] to know which registry it belongs to.
  final String? giftMementoId;
  // Optional free-text label for non-memento rewards (Cod, plates, diamonds…)
  final String? giftLabel;

  /// 'memento', 'facility', 'unresolved', or null for a currency gift.
  ///
  /// This and [giftRefId] used to be dropped on the floor, so every gift was
  /// looked up in the memento index and the 38 facility gifts came out as
  /// plain text with a dead checkbox — 40 of the 91 codes could not be ticked
  /// off at all.
  final String? giftKind;

  /// The id inside the registry [giftKind] names.
  final String? giftRefId;

  RedemptionCode({
    required this.code,
    required this.validFrom,
    required this.validUntil,
    required this.reason,
    this.giftMementoId,
    this.giftLabel,
    this.giftKind,
    this.giftRefId,
  });

  /// Parses dates safely:
  /// - Supports "YYYY-MM-DD" and "YYYY-M-D"
  /// - If null/invalid, falls back to a safe default
  static DateTime _parseDateOrFallback(
    dynamic value, {
    required DateTime fallback,
  }) {
    if (value == null) return fallback;

    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return fallback;

    // Try strict ISO parse first.
    try {
      return DateTime.parse(s);
    } catch (_) {
      // Then try flexible YYYY-M-D
      final parts = s.split('-');
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          try {
            return DateTime(y, m, d);
          } catch (_) {}
        }
      }
      return fallback;
    }
  }

  factory RedemptionCode.fromJson(Map<String, dynamic> json) {
    // Fallbacks:
    // - If a code has no start date, keep it very old so it sorts to the bottom.
    // - If a code has no end date, treat as far-future (permanent-ish).
    final fallbackFrom = DateTime(1970, 1, 1);
    final fallbackUntil = DateTime(2099, 12, 31);

    final parsedFrom = _parseDateOrFallback(
      json['validFrom'],
      fallback: fallbackFrom,
    );

    final parsedUntil = _parseDateOrFallback(
      json['validUntil'],
      fallback: fallbackUntil,
    );

    return RedemptionCode(
      code: json['code'] as String,
      validFrom: parsedFrom,
      validUntil: parsedUntil,
      reason: (json['reason'] as String?) ?? '',
      giftMementoId: json['giftMementoId'] as String?,
      giftLabel: json['giftLabel'] as String?,
      giftKind: json['giftKind'] as String?,
      giftRefId: json['giftRefId'] as String?,
    );
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();
    // inclusive range: valid on both start and end dates
    return !now.isBefore(validFrom) && !now.isAfter(validUntil);
  }
}

/// A gift resolved to something the page can name, open and tick off.
///
/// Mementos and facilities live in different registries and different progress
/// buckets, so the row carries both the bucket and the key rather than
/// assuming 'memento_collected'.
class _Gift {
  final String bucket;
  final String key;
  final String name;
  final MementoEntry? memento;
  final Facility? facility;

  const _Gift._({
    required this.bucket,
    required this.key,
    required this.name,
    this.memento,
    this.facility,
  });

  factory _Gift.memento(MementoEntry m) => _Gift._(
        bucket: 'memento_collected',
        key: m.key,
        name: m.name,
        memento: m,
      );

  factory _Gift.facility(Facility f) => _Gift._(
        bucket: 'facility',
        key: f.id,
        name: f.name,
        facility: f,
      );
}

class _CodeWithGift {
  final RedemptionCode code;
  final _Gift? gift;

  _CodeWithGift({required this.code, required this.gift});
}

enum RedemptionSortColumn {
  code,
  valid,
  date,
  owned,
}

class RedemptionCodesPage extends StatefulWidget {
  const RedemptionCodesPage({super.key});

  @override
  State<RedemptionCodesPage> createState() => _RedemptionCodesPageState();
}

class _RedemptionCodesPageState extends State<RedemptionCodesPage> {
  String _query = '';

  final store = UnlockedStore.instance;
  late Future<List<_CodeWithGift>> _future;

  // NEW: clickable column sort state
  RedemptionSortColumn _sortColumn = RedemptionSortColumn.date;
  bool _ascending = false; // default: Date newest first (descending)

  // Show only codes that are currently redeemable.
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_CodeWithGift>> _load() async {
    // Both registries: a code's gift is a memento or a facility, and which one
    // it is comes from giftKind in the data.
    final mementos = await MementosIndex.instance.all();
    final mementosById = {for (final m in mementos) m.id: m};

    final facilities = await FacilitiesRepository.instance.all();
    final facilitiesById = {for (final f in facilities) f.id: f};

    final raw =
        await JsonLoader.load('assets/data/redemption_codes.json') as List<dynamic>;

    final codes = raw
        .map((e) => RedemptionCode.fromJson(e as Map<String, dynamic>))
        .toList();

    // default order in data (doesn't matter much because we sort in UI)
    codes.sort((a, b) => b.validFrom.compareTo(a.validFrom));

    return codes.map((c) => _CodeWithGift(code: c, gift: _resolveGift(
          c,
          mementosById: mementosById,
          facilitiesById: facilitiesById,
        ))).toList();
  }

  /// Resolves one code's gift, or null for a currency gift and for the two
  /// codes the data itself marks 'unresolved'.
  ///
  /// The kind is trusted first and the other registry is tried as a fallback,
  /// so a gift mislabelled in the data still links rather than dead-ending.
  static _Gift? _resolveGift(
    RedemptionCode c, {
    required Map<String, MementoEntry> mementosById,
    required Map<String, Facility> facilitiesById,
  }) {
    final id = c.giftRefId ?? c.giftMementoId;
    if (id == null) return null;

    final memento = mementosById[id];
    final facility = facilitiesById[id];

    switch (c.giftKind) {
      case 'facility':
        if (facility != null) return _Gift.facility(facility);
        break;
      case 'memento':
        if (memento != null) return _Gift.memento(memento);
        break;
    }

    if (memento != null) return _Gift.memento(memento);
    if (facility != null) return _Gift.facility(facility);
    return null;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool _isOwned(_CodeWithGift item) {
    final g = item.gift;
    if (g == null) return false;
    return store.isUnlocked(g.bucket, g.key);
  }

  void _sortItems(List<_CodeWithGift> items) {
    int cmpBool(bool a, bool b) {
      if (a == b) return 0;
      return a ? 1 : -1; // false < true in ascending
    }

    int cmpStr(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    int cmpDate(DateTime a, DateTime b) => a.compareTo(b);

    items.sort((a, b) {
      int result = 0;

      switch (_sortColumn) {
        case RedemptionSortColumn.code:
          result = cmpStr(a.code.code, b.code.code);
          break;

        case RedemptionSortColumn.valid:
          // valid false/true (ascending puts invalid first, descending puts valid first)
          result = cmpBool(a.code.isCurrentlyValid, b.code.isCurrentlyValid);
          break;

        case RedemptionSortColumn.date:
          // use validFrom as the sort date
          result = cmpDate(a.code.validFrom, b.code.validFrom);
          break;

        case RedemptionSortColumn.owned:
          // owned false/true
          result = cmpBool(_isOwned(a), _isOwned(b));
          break;
      }

      if (!_ascending) result = -result;

      // stable-ish tie breaker: always by code (A-Z)
      if (result == 0) {
        result = cmpStr(a.code.code, b.code.code);
      }
      return result;
    });
  }

  void _toggleSort(RedemptionSortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _ascending = !_ascending; // tap same header toggles direction
      } else {
        _sortColumn = col;
        // choose sensible defaults per column
        switch (col) {
          case RedemptionSortColumn.code:
            _ascending = true; // A-Z first
            break;
          case RedemptionSortColumn.valid:
            _ascending = false; // valid first
            break;
          case RedemptionSortColumn.date:
            _ascending = false; // newest first
            break;
          case RedemptionSortColumn.owned:
            _ascending = false; // owned first
            break;
        }
      }
    });
  }

  Widget _sortHeaderCell({
    required BuildContext context,
    required int flex,
    required String label,
    required RedemptionSortColumn column,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final theme = Theme.of(context);
    final isActive = _sortColumn == column;

    final arrow = isActive
        ? Icon(
            _ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: theme.textTheme.bodyMedium?.color,
          )
        : const SizedBox(width: 14);

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _toggleSort(column),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                arrow,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGift(_Gift g) {
    final memento = g.memento;
    final facility = g.facility;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => memento != null
            ? MementoDetailPage(memento: memento)
            : FacilityDetailPage(facilityId: facility!.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption Codes'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return FutureBuilder<List<_CodeWithGift>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allItems = [...snapshot.data!];
              if (allItems.isEmpty) {
                return const Center(child: Text('No redemption codes yet.'));
              }

              final activeCount =
                  allItems.where((it) => it.code.isCurrentlyValid).length;

              // Copy before sorting: _sortItems mutates in place, and
              // allItems is the shared source list.
              final items = allItems
                  .where((it) {
                    // Match the gift text the row actually renders.
                    final giftText =
                        it.gift?.name ?? it.code.giftLabel ?? '';
                    return (!_activeOnly || it.code.isCurrentlyValid) &&
                        matchesQuery(
                          _query,
                          '${it.code.code} ${it.code.reason} $giftText',
                        );
                  })
                  .toList();

              // apply sort
              _sortItems(items);

              // Gifts span two buckets, so the counter and the check-all both
              // work per bucket. A code with a currency gift has nothing to
              // tick and stays out of both.
              final gifts = items.map((it) => it.gift).whereType<_Gift>();
              final keysByBucket = <String, Set<String>>{};
              for (final g in gifts) {
                (keysByBucket[g.bucket] ??= <String>{}).add(g.key);
              }
              final rewardTargets = <CheckAllTarget>[
                for (final e in keysByBucket.entries)
                  CheckAllTarget(e.key, e.value.toList()),
              ];
              final rewardCount = keysByBucket.values
                  .fold<int>(0, (n, keys) => n + keys.length);
              final ownedRewards = keysByBucket.entries.fold<int>(
                0,
                (n, e) =>
                    n + e.value.where((k) => store.isUnlocked(e.key, k)).length,
              );

              return Column(
                children: [
                  SearchField(
                    hintText: 'Search codes, rewards, or reason…',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('Active only ($activeCount)'),
                          selected: _activeOnly,
                          onSelected: (v) => setState(() => _activeOnly = v),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${items.length} shown • '
                            'gifts $ownedRewards/$rewardCount',
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        CheckAllButton.multi(
                          targets: rewardTargets,
                          groupLabel: 'Redemption code gifts',
                        ),
                      ],
                    ),
                  ),
                  // header row = clickable "table" header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _sortHeaderCell(
                          context: context,
                          flex: 2,
                          label: 'Code',
                          column: RedemptionSortColumn.code,
                          alignment: Alignment.centerLeft,
                        ),
                        _sortHeaderCell(
                          context: context,
                          flex: 1,
                          label: 'Valid',
                          column: RedemptionSortColumn.valid,
                          alignment: Alignment.center,
                        ),
                        _sortHeaderCell(
                          context: context,
                          flex: 3,
                          label: 'Date',
                          column: RedemptionSortColumn.date,
                          alignment: Alignment.centerLeft,
                        ),
                        _sortHeaderCell(
                          context: context,
                          flex: 3,
                          label: 'Owned',
                          column: RedemptionSortColumn.owned,
                          alignment: Alignment.centerLeft,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final c = item.code;
                        final g = item.gift;

                        final currentlyValid = c.isCurrentlyValid;
                        final icon =
                            currentlyValid ? Icons.check_circle : Icons.cancel;
                        final iconColor =
                            currentlyValid ? Colors.green : Colors.redAccent;

                        final owned = g != null && _isOwned(item);

                        final giftText = g?.name ?? item.code.giftLabel ?? '—';

                        return InkWell(
                          onTap: g != null ? () => _openGift(g) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () => _copyCode(context, c.code),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        c.code,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Icon(icon, color: iconColor),
                                  ),
                                ),

                                // Validity range
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${_formatDate(c.validFrom)}\n→ ${_formatDate(c.validUntil)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),

                                // Gift + owned checkbox
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (g != null)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: () => _openGift(g),
                                          child: Text(
                                            giftText,
                                            style: const TextStyle(
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          giftText,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: owned,
                                            onChanged: g == null
                                                ? null
                                                : (v) => store.setUnlocked(
                                                      g.bucket,
                                                      g.key,
                                                      v ?? false,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}
