import 'package:flutter/material.dart';

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

  factory RedemptionCode.fromJson(Map<String, dynamic> json) {
    return RedemptionCode(
      code: json['code'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
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

enum RedemptionSortMode {
  dateDesc,
  owned,
  startMonthDesc,
}

class RedemptionCodesPage extends StatefulWidget {
  const RedemptionCodesPage({super.key});

  @override
  State<RedemptionCodesPage> createState() => _RedemptionCodesPageState();
}

class _RedemptionCodesPageState extends State<RedemptionCodesPage> {
  final store = UnlockedStore.instance;
  late Future<List<_CodeWithMemento>> _future;
  RedemptionSortMode _sortMode = RedemptionSortMode.dateDesc;

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
    final raw = await JsonLoader.load('assets/data/redemption_codes.json')
        as List<dynamic>;

    final codes = raw
        .map((e) => RedemptionCode.fromJson(e as Map<String, dynamic>))
        .toList();

    // Default sort: newest start date first
    codes.sort((a, b) => b.validFrom.compareTo(a.validFrom));

    return codes
        .map(
          (c) => _CodeWithMemento(
            code: c,
            memento: c.giftMementoId != null
                ? mementosById[c.giftMementoId!]
                : null,
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

  void _sortItems(List<_CodeWithMemento> items) {
    switch (_sortMode) {
      case RedemptionSortMode.dateDesc:
        items.sort(
          (a, b) => b.code.validFrom.compareTo(a.code.validFrom),
        );
        break;

      case RedemptionSortMode.owned:
        items.sort((a, b) {
          final aOwned = a.memento != null &&
              store.isUnlocked('memento_collected', a.memento!.key);
          final bOwned = b.memento != null &&
              store.isUnlocked('memento_collected', b.memento!.key);

          if (aOwned != bOwned) {
            // owned first
            return aOwned ? -1 : 1;
          }
          // then by date (newest first)
          return b.code.validFrom.compareTo(a.code.validFrom);
        });
        break;

      case RedemptionSortMode.startMonthDesc:
        items.sort((a, b) {
          final aKey = a.code.validFrom.year * 100 + a.code.validFrom.month;
          final bKey = b.code.validFrom.year * 100 + b.code.validFrom.month;
          return bKey.compareTo(aKey); // latest month first
        });
        break;
    }
  }

  String _sortModeLabel(RedemptionSortMode mode) {
    switch (mode) {
      case RedemptionSortMode.dateDesc:
        return 'Date (newest first)';
      case RedemptionSortMode.owned:
        return 'Owned first';
      case RedemptionSortMode.startMonthDesc:
        return 'Starting month';
    }
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
        actions: [
          PopupMenuButton<RedemptionSortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) {
              setState(() {
                _sortMode = mode;
              });
            },
            itemBuilder: (context) => [
              for (final mode in RedemptionSortMode.values)
                PopupMenuItem(
                  value: mode,
                  child: Text(_sortModeLabel(mode)),
                ),
            ],
          ),
        ],
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
                  // header row = "table" header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('Code')),
                        Expanded(
                          flex: 1,
                          child: Center(child: Text('Valid now')),
                        ),
                        Expanded(flex: 3, child: Text('Validity range')),
                        // We no longer show the reason in the table
                        // Expanded(flex: 3, child: Text('Reason')),
                        Expanded(flex: 3, child: Text('Gift / Owned')),
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
                        final icon = currentlyValid
                            ? Icons.check_circle
                            : Icons.cancel;
                        final iconColor = currentlyValid
                            ? Colors.green
                            : Colors.redAccent;

                        final owned = m != null
                            ? store.isUnlocked('memento_collected', m.key)
                            : false;

                        final giftText =
                            m?.name ?? item.code.giftLabel ?? '—';

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
                                // Code
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    c.code,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),

                                // Valid now (icon)
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

                                // Gift + owned checkbox (no reason column anymore)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              decoration:
                                                  TextDecoration.underline,
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
}
