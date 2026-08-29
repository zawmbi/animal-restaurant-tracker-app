import 'package:flutter/material.dart';

import 'facility.dart';

/// Lists the cooking-efficiency bonus of each stove.
///
/// It deliberately does **not** turn that percentage into a cook time. The
/// wiki prints stoves as "+N% efficiency" and the game's own tutorial only
/// says "buy a few more stoves and the cooking speed will increase"; neither
/// publishes how the percentage maps onto seconds, and the percentages of
/// every stove in the game add up to over 3,000%, which cannot be a
/// straight subtraction from cook time. Showing a confident "cook time:
/// 43.2 s" from an unpublished formula would be worse than showing nothing,
/// so this widget shows the bonus and says what is not known.
class StoveCookCalculator extends StatelessWidget {
  const StoveCookCalculator({super.key, required this.stoves});

  final List<Facility> stoves;

  @override
  Widget build(BuildContext context) {
    // Sorted by bonus, with an id tie-break: Dart's List.sort is not stable,
    // so equal bonuses would otherwise reshuffle between builds.
    final sorted = stoves.toList()
      ..sort((a, b) {
        final byBonus =
            b.cookingEfficiencyPercent.compareTo(a.cookingEfficiencyPercent);
        return byBonus != 0 ? byBonus : a.id.compareTo(b.id);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stove cooking efficiency',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'The game does not publish how a stove\'s efficiency percentage '
          'converts into cook time, so this list shows the bonus itself '
          'rather than a cook time derived from a formula nobody has.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final stove in sorted)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(stove.name),
              subtitle: Text(
                stove.cookingEfficiencyPercent > 0
                    ? 'Efficiency: +${stove.cookingEfficiencyPercent.toStringAsFixed(1)}%'
                    : 'No published efficiency bonus',
              ),
              trailing: Text(stove.group),
            ),
          ),
      ],
    );
  }
}
