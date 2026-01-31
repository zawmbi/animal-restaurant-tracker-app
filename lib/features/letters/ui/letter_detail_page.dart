// lib/features/letters/ui/letter_detail_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../model/letter.dart';
import '../data/letters_repository.dart';

import '../../shared/data/unlocked_store.dart';

// Customers
import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart';

// Facilities
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/ui/facility_detail_page.dart';

// Mementos
import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

import '../../dishes/data/dishes_repository.dart';
import '../../dishes/ui/dish_detail_page.dart';

class LetterDetailPage extends StatefulWidget {
  final Letter letter;
  const LetterDetailPage({super.key, required this.letter});

  @override
  State<LetterDetailPage> createState() => _LetterDetailPageState();
}

class _LetterDetailPageState extends State<LetterDetailPage> {
  final store = UnlockedStore.instance;

  static const String _bucketLetter = 'letter';
  static const String _bucketCustomer = 'customer';
  static const String _bucketFacility = 'facility';
  static const String _bucketMementoCollected = 'memento_collected';
  static const String _bucketDish = 'dish';

  static const String _starAsset = 'assets/images/star.png';

  Letter get letter => widget.letter;

  Color _ownedFill(BuildContext context) => Colors.green.withOpacity(0.18);

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketLetter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownedFill = _ownedFill(context);
    final combos = letter.combinations;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final isOwned = store.isUnlocked(_bucketLetter, letter.id);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: kToolbarHeight * 1.5,
            title: Text(
              letter.name,
              maxLines: null,
            ),
            actions: [
              Checkbox(
                value: isOwned,
                onChanged: (v) {
                  store.setUnlocked(_bucketLetter, letter.id, v ?? false);
                  setState(() {});
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (letter.obtainMethod != null && letter.obtainMethod!.trim().isNotEmpty) ...[
                Text(
                  'How to Obtain',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(letter.obtainMethod!),
                ),
                const SizedBox(height: 16),
              ],

              if (combos.isNotEmpty) _CombinationTable(combinations: combos),
              if (combos.isNotEmpty) const SizedBox(height: 16),

              if (letter.description != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(letter.description!, textAlign: TextAlign.center),
                ),

              const SizedBox(height: 16),

              _infoRow(
                label: 'Bonus',
                value: _BonusValue(raw: letter.earnedStars ?? '—', starAsset: _starAsset),
              ),

              _ownedLinkRow(label: 'Unlocks', raw: letter.unlocks, fillIfOwned: ownedFill),
              _ownedLinkRow(label: 'Prerequisite', raw: letter.prerequisite, fillIfOwned: ownedFill),

              if (letter.unlockRequirement != null && letter.unlockRequirement!.trim().isNotEmpty)
                _ownedLinkRow(
                  label: 'Unlock Requirement',
                  raw: letter.unlockRequirement,
                  fillIfOwned: ownedFill,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow({required String label, required Widget value}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _ownedLinkRow({
    required String label,
    required String? raw,
    required Color fillIfOwned,
  }) {
    final text = (raw ?? '—').trim();
    if (text.isEmpty || text == '—' || text == '-') {
      return _infoRow(label: label, value: Text(text.isEmpty ? '—' : text));
    }

    // Split by comma and trim each item
    final items = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    if (items.isEmpty) {
      return _infoRow(label: label, value: Text(text));
    }

    // If single item, resolve it directly
    if (items.length == 1) {
      return _infoRow(
        label: label,
        value: FutureBuilder<_ResolvedTarget?>(
          future: _resolve(items[0]),
          builder: (context, snap) {
            final target = snap.data;
            if (target == null) return Text(items[0]);

            final owned = target.owned;
            final childText = Text(
              items[0],
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.none,
              ),
            );

            final clickable = InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                await _openTarget(target);
                if (mounted) setState(() {});
              },
              child: owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: fillIfOwned,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: childText,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: childText,
                    ),
            );

            return UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: clickable,
            );
          },
        ),
      );
    }

    // Multiple items - show them in a Wrap
    return _infoRow(
      label: label,
      value: FutureBuilder<List<_ResolvedTarget?>>(
        future: Future.wait(items.map((item) => _resolve(item))),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: items.map((item) => Text(item)).toList(),
            );
          }

          final targets = snap.data!;
          final widgets = <Widget>[];

          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final target = targets[i];

            if (target == null) {
              widgets.add(Text(item));
            } else {
              final owned = target.owned;
              final childText = Text(
                item,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.none,
                ),
              );

              final clickable = InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () async {
                  await _openTarget(target);
                  if (mounted) setState(() {});
                },
                child: owned
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: fillIfOwned,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: childText,
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: childText,
                      ),
              );

              widgets.add(UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: clickable,
              ));
            }

            // Add comma separator except for last item
            if (i < items.length - 1) {
              widgets.add(const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(','),
              ));
            }
          }

          return Wrap(
            spacing: 0,
            runSpacing: 4,
            children: widgets,
          );
        },
      ),
    );
  }

  Future<void> _openTarget(_ResolvedTarget t) async {
    if (t is _LetterTarget) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LetterDetailPage(letter: t.letter)),
      );
      return;
    }
    if (t is _CustomerTarget) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: t.customer)),
      );
      return;
    }
    if (t is _FacilityTarget) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FacilityDetailPage(facilityId: t.facility.id)),
      );
      return;
    }
    if (t is _MementoTarget) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MementoDetailPage(memento: t.memento)),
      );
      return;
    }
    if (t is _DishTarget) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DishDetailPage(dishId: t.dish.id)),
      );
      return;
    }
  }

  Future<_ResolvedTarget?> _resolve(String value) async {
    final valueLower = value.trim().toLowerCase();
    
    // Try letters by name or ID
    final letters = await LettersRepository.instance.all();
    var l = letters.firstWhereOrNull((e) => _eq(e.name, value));
    l ??= letters.firstWhereOrNull((e) => _eq(e.id, valueLower));
    if (l != null && l.id != letter.id) {
      return _LetterTarget(l, owned: store.isUnlocked(_bucketLetter, l.id));
    }

    // Try customers by name or ID
    final customers = await CustomersRepository.instance.all();
    var c = customers.firstWhereOrNull((e) => _eq(e.name, value));
    c ??= customers.firstWhereOrNull((e) => _eq(e.id, valueLower));
    if (c != null) {
      final cid = _tryGetId(c);
      return _CustomerTarget(
        c,
        owned: (cid != null) ? store.isUnlocked(_bucketCustomer, cid) : false,
      );
    }

    // Try facilities by name or ID
    final facilities = await FacilitiesRepository.instance.all();
    var f = facilities.firstWhereOrNull((e) => _eq(e.name, value));
    f ??= facilities.firstWhereOrNull((e) => _eq(e.id, valueLower));
    if (f != null) {
      final fid = _tryGetId(f);
      return _FacilityTarget(
        f,
        owned: (fid != null) ? store.isUnlocked(_bucketFacility, fid) : false,
      );
    }

    // Try mementos by ID
    var m = await MementosIndex.instance.byId(valueLower);
    if (m != null) {
      return _MementoTarget(m, owned: store.isUnlocked(_bucketMementoCollected, m.key));
    }

    // Try dishes by name or ID
    final dishes = await DishesRepository.instance.all();
    var d = dishes.firstWhereOrNull((e) => _eq(e.name, value));
    d ??= dishes.firstWhereOrNull((e) => _eq(e.id, valueLower));
    if (d != null) {
      final did = _tryGetId(d);
      return _DishTarget(
        d,
        owned: (did != null) ? store.isUnlocked(_bucketDish, did) : false,
      );
    }

    return null;
  }

  String? _tryGetId(dynamic obj) {
    try {
      final v = obj.id;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  bool _eq(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();
}

class _BonusValue extends StatelessWidget {
  final String raw;
  final String starAsset;

  const _BonusValue({required this.raw, required this.starAsset});

  @override
  Widget build(BuildContext context) {
    final v = raw.trim();
    if (v.isEmpty || v == '—') return Text(v.isEmpty ? '—' : v);

    final m = RegExp(r'[-+]?\d+').firstMatch(v);
    if (m == null) return Text(v);

    final number = m.group(0)!;
    final display = (number.startsWith('+') || number.startsWith('-')) ? number : '+$number';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(display),
        const SizedBox(width: 4),
        Image.asset(starAsset, width: 16, height: 16, fit: BoxFit.contain),
      ],
    );
  }
}

sealed class _ResolvedTarget {
  final bool owned;
  const _ResolvedTarget({required this.owned});
}

class _LetterTarget extends _ResolvedTarget {
  final Letter letter;
  const _LetterTarget(this.letter, {required super.owned});
}

class _CustomerTarget extends _ResolvedTarget {
  final dynamic customer;
  const _CustomerTarget(this.customer, {required super.owned});
}

class _FacilityTarget extends _ResolvedTarget {
  final dynamic facility;
  const _FacilityTarget(this.facility, {required super.owned});
}

class _MementoTarget extends _ResolvedTarget {
  final dynamic memento;
  const _MementoTarget(this.memento, {required super.owned});
}

class _DishTarget extends _ResolvedTarget {
  final dynamic dish;
  const _DishTarget(this.dish, {required super.owned});
}

class _CombinationTable extends StatelessWidget {
  final List<LetterCombination> combinations;
  const _CombinationTable({required this.combinations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 1',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 2',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 3',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final c in combinations)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.4))),
              ),
              child: Row(
                children: [
                  Expanded(child: _slotText(c.slot1)),
                  Expanded(child: _slotText(c.slot2)),
                  Expanded(child: _slotText(c.slot3)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _slotText(String value) {
    if (value.trim() == '*') {
      return const Center(child: Text('*', style: TextStyle(fontStyle: FontStyle.italic)));
    }
    return Center(child: Text(value));
  }
}
