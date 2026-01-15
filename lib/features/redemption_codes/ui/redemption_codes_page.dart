import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/data/unlocked_store.dart';
import '../../shared/json_loader.dart';
import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

class RedemptionCode {
  final String code;
  final DateTime validFrom;
  final DateTime validUntil;
  final String reason;
  // If this is a memento reward, this is the memento id from mementos.json
  final String? giftMementoId;
  // Optional free-text label for non-memento rewards (Cod, plates, diamonds…)
  final String? giftLabel;

  RedemptionCode({
    required this.code,
    required this.validFrom,
    required this.validUntil,
    required this.reason,
    this.giftMementoId,
    this.giftLabel,
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
    );
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();
    // inclusive range: valid on both start and end dates
    return !now.isBefore(validFrom) && !now.isAfter(validUntil);
  }
}

class _CodeWithMemento {
  final RedemptionCode code;
  final MementoEntry? memento;

  _CodeWithMemento({required this.code, required this.memento});
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
  final store = UnlockedStore.instance;
  late Future<List<_CodeWithMemento>> _future;

  // NEW: clickable column sort state
  RedemptionSortColumn _sortColumn = RedemptionSortColumn.date;
  bool _ascending = false; // default: Date newest first (descending)

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_CodeWithMemento>> _load() async {
    // 1) Load all mementos so we can link gifts by id
    final mementos = await MementosIndex.instance.all();
    final mementosById = {for (final m in mementos) m.id: m};

    // 2) Load redemption codes from JSON
    final raw =
        await JsonLoader.load('assets/data/redemption_codes.json') as List<dynamic>;

    final codes = raw
        .map((e) => RedemptionCode.fromJson(e as Map<String, dynamic>))
        .toList();

    // default order in data (doesn't matter much because we sort in UI)
    codes.sort((a, b) => b.validFrom.compareTo(a.validFrom));

    return codes
        .map(
          (c) => _CodeWithMemento(
            code: c,
            memento: c.giftMementoId != null ? mementosById[c.giftMementoId!] : null,
          ),
        )
        .toList();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool _isOwned(_CodeWithMemento item) {
    final m = item.memento;
    if (m == null) return false;
    return store.isUnlocked('memento_collected', m.key);
  }

  void _sortItems(List<_CodeWithMemento> items) {
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

  void _openMemento(MementoEntry m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MementoDetailPage(memento: m),
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
          return FutureBuilder<List<_CodeWithMemento>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = [...snapshot.data!];
              if (items.isEmpty) {
                return const Center(child: Text('No redemption codes yet.'));
              }

              // apply sort
              _sortItems(items);

              return Column(
                children: [
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
                        final m = item.memento;

                        final currentlyValid = c.isCurrentlyValid;
                        final icon =
                            currentlyValid ? Icons.check_circle : Icons.cancel;
                        final iconColor =
                            currentlyValid ? Colors.green : Colors.redAccent;

                        final owned = m != null ? _isOwned(item) : false;

                        final giftText = m?.name ?? item.code.giftLabel ?? '—';

                        return InkWell(
                          onTap: m != null ? () => _openMemento(m) : null,
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
                                      if (m != null)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: () => _openMemento(m),
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
                                            onChanged: m == null
                                                ? null
                                                : (v) => store.setUnlocked(
                                                      'memento_collected',
                                                      m.key,
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
