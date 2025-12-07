import 'package:flutter/material.dart';
import '../model/letter.dart';

class LetterDetailPage extends StatelessWidget {
  final Letter letter;

  const LetterDetailPage({super.key, required this.letter});

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
            if (letter.imageAsset != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    letter.imageAsset!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (letter.imageAsset != null) const SizedBox(height: 16),

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

            _InfoRow(label: 'Bonus', value: letter.bonus ?? '—'),
            _InfoRow(label: 'Unlocks', value: letter.unlocks ?? '—'),
            _InfoRow(label: 'Prerequisite', value: letter.prerequisite ?? '—'),
          ],
        ),
      ),
    );
  }
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
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
