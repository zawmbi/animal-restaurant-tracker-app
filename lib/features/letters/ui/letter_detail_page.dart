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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownedFill = _ownedFill(context);
    final combos = letter.combinations;

    return Scaffold(
      appBar: AppBar(title: Text(letter.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (letter.obtainMethod != null && letter.obtainMethod!.trim().isNotEmpty) ...[
            const Text(
              'How to Obtain',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            value: _BonusValue(raw: letter.bonus ?? '—', starAsset: _starAsset),
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
    if (text.isEmpty || text == '—') {
      return _infoRow(label: label, value: Text(text.isEmpty ? '—' : text));
    }

    return _infoRow(
      label: label,
      value: FutureBuilder<_ResolvedTarget?>(
        future: _resolve(text),
        builder: (context, snap) {
          final target = snap.data;
          if (target == null) return Text(text);

          final owned = target.owned;

          final childText = Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.none, // no underline
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

          // IMPORTANT: make the owned pill fit content (not full-width)
          return UnconstrainedBox(
            alignment: Alignment.centerLeft,
            child: clickable,
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
    final letters = await LettersRepository.instance.all();
    final l = letters.firstWhereOrNull((e) => _eq(e.name, value));
    if (l != null && l.id != letter.id) {
      return _LetterTarget(l, owned: store.isUnlocked(_bucketLetter, l.id));
    }

    final customers = await CustomersRepository.instance.all();
    final c = customers.firstWhereOrNull((e) => _eq(e.name, value));
    if (c != null) {
      final cid = _tryGetId(c);
      return _CustomerTarget(
        c,
        owned: (cid != null) ? store.isUnlocked(_bucketCustomer, cid) : false,
      );
    }

    final facilities = await FacilitiesRepository.instance.all();
    final f = facilities.firstWhereOrNull((e) => _eq(e.name, value));
    if (f != null) {
      final fid = _tryGetId(f);
      return _FacilityTarget(
        f,
        owned: (fid != null) ? store.isUnlocked(_bucketFacility, fid) : false,
      );
    }

    final m = await MementosIndex.instance.byId(value);
    if (m != null) {
      return _MementoTarget(m, owned: store.isUnlocked(_bucketMementoCollected, m.key));
    }

    final dishes = await DishesRepository.instance.all();
    final d = dishes.firstWhereOrNull((e) => _eq(e.name, value));
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
            child: const Row(
              children: [
                Expanded(child: Center(child: Text('Slot 1', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Slot 2', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Slot 3', style: TextStyle(fontWeight: FontWeight.bold)))),
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
