// lib/features/letters/ui/letter_detail_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../model/letter.dart';
import '../data/letters_repository.dart';

import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart';

class LetterDetailPage extends StatelessWidget {
  final Letter letter;

  const LetterDetailPage({super.key, required this.letter});

  static const String _starAsset = 'assets/images/star.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final combos = letter.combinations;

    return Scaffold(
      appBar: AppBar(
        title: Text(letter.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [


            if (combos.isNotEmpty) _CombinationTable(combinations: combos),

            const SizedBox(height: 16),

            if (letter.description != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  letter.description!,
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Bonus row: render "+60" and use your star PNG instead of ★
            _InfoRow(
              label: 'Bonus',
              valueWidget: _BonusValue(
                raw: letter.bonus ?? '—',
                starAsset: _starAsset,
              ),
            ),

            // Unlocks row: clickable if it matches a Letter or Customer
            _InfoRow(
              label: 'Unlocks',
              valueWidget: _LinkableValue(
                raw: letter.unlocks ?? '—',
                currentLetterId: letter.id,
              ),
            ),

            // Prerequisite row: clickable if it matches a Letter or Customer
            _InfoRow(
              label: 'Prerequisite',
              valueWidget: _LinkableValue(
                raw: letter.prerequisite ?? '—',
                currentLetterId: letter.id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusValue extends StatelessWidget {
  final String raw;
  final String starAsset;

  const _BonusValue({
    required this.raw,
    required this.starAsset,
  });

  @override
  Widget build(BuildContext context) {
    final v = raw.trim();
    if (v.isEmpty || v == '—') return Text(v.isEmpty ? '—' : v);

    // Common formats:
    // "+60★" / "+60 ★" / "60★" / "60 ★" / "+60"
    final cleaned = v.replaceAll('★', '').trim();

    final showsStar = v.contains('★');
    if (!showsStar) return Text(v);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(cleaned),
        const SizedBox(width: 4),
        Image.asset(
          starAsset,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _LinkableValue extends StatelessWidget {
  final String raw;
  final String currentLetterId;

  const _LinkableValue({
    required this.raw,
    required this.currentLetterId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = raw.trim();

    if (text.isEmpty || text == '—') {
      return Text(text.isEmpty ? '—' : text);
    }

    return FutureBuilder<_ResolvedTarget?>(
      future: _resolve(text, currentLetterId),
      builder: (context, snap) {
        final target = snap.data;

        // Not resolved (or still loading) => just show plain text (keeps formatting consistent)
        if (target == null) {
          return Text(text);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            if (target is _LetterTarget) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LetterDetailPage(letter: target.letter),
                ),
              );
            } else if (target is _CustomerTarget) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerDetailPage(customer: target.customer),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_ResolvedTarget?> _resolve(String value, String currentLetterId) async {
    // 1) Try letters by name (e.g., "Lucky's Letter")
    final letters = await LettersRepository.instance.all();
    final letter = letters.firstWhere(
      (l) => _eq(l.name, value),
      orElse: () => const Letter(
        id: '__none__',
        name: '__none__',
      ),
    );
    if (letter.id != '__none__' && letter.id != currentLetterId) {
      return _LetterTarget(letter);
    }

    // 2) Try customers by name (in case prerequisite/unlocks is a customer)
    final customers = await CustomersRepository.instance.all();
    final customer = customers.firstWhereOrNull(
      (c) => _eq(c.name, value),
    );

    // The hack above is to avoid requiring a dummy Customer constructor;
    // so we only accept if it actually matched by name.
    if (customer != null && _eq(customer.name, value)) {
      return _CustomerTarget(customer);
    }

    return null;
  }

  bool _eq(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();
}

sealed class _ResolvedTarget {}

class _LetterTarget extends _ResolvedTarget {
  final Letter letter;
  _LetterTarget(this.letter);
}

class _CustomerTarget extends _ResolvedTarget {
  final dynamic customer; // keep flexible with your Customer model type
  _CustomerTarget(this.customer);
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
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 1',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 2',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Slot 3',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.4),
                  ),
                ),
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
      return const Center(
        child: Text(
          '*',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    return Center(child: Text(value));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget? valueWidget;

  const _InfoRow({
    required this.label,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: valueWidget ?? const Text('—'),
          ),
        ],
      ),
    );
  }
}
