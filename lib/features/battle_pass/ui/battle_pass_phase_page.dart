import 'package:flutter/material.dart';

import '../model/battle_pass.dart';
import 'battle_pass_reward_box.dart';

class BattlePassPhasePage extends StatelessWidget {
  final BattlePass pass;
  final BattlePassPhase phase;

  const BattlePassPhasePage({
    super.key,
    required this.pass,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (phase.start.isNotEmpty || phase.end.isNotEmpty)
                  Text('Dates: ${phase.start} → ${phase.end}'),
                if (phase.completionNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(phase.completionNote),
                ],
                if (pass.seasonDays > 0) ...[
                  const SizedBox(height: 8),
                  Text('Season length: ${pass.seasonDays} days'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Rewards header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                SizedBox(
                  width: 70,
                  child: Text('EXP',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('Normal',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Super',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        ...phase.tiers.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text('EXP ${tier.exp}'),
                    ),
                    Expanded(
                      child: BattlePassRewardBox(
                        rewards: tier.normalRewards,
                        isSuper: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BattlePassRewardBox(
                        rewards: tier.superRewards,
                        isSuper: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
