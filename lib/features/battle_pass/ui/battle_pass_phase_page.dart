import 'package:flutter/material.dart';

import '../../completion/data/completion_service.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
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

  /// Claim keys for this phase. Super only counts once the pass's premium tier
  /// is owned, matching BattlePassDetailPage.
  List<String> _claimKeys(UnlockedStore store) {
    final premium =
        store.isUnlocked(ProgressTypes.battlePassPremium, pass.id);
    final keys = <String>[];
    for (final tier in phase.tiers) {
      keys.add(CompletionService.battlePassClaimKey(
        passId: pass.id,
        phaseId: phase.id,
        track: 'normal',
        exp: tier.exp,
      ));
      if (premium) {
        keys.add(CompletionService.battlePassClaimKey(
          passId: pass.id,
          phaseId: phase.id,
          track: 'super',
          exp: tier.exp,
        ));
      }
    }
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = UnlockedStore.instance;

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

        // Claim-all for this whole phase
        AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final keys = _claimKeys(store);
            final claimed = keys
                .where((k) =>
                    store.isUnlocked(ProgressTypes.battlePassClaimed, k))
                .length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Claimed: $claimed/${keys.length}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  CheckAllButton(
                    bucket: ProgressTypes.battlePassClaimed,
                    ids: keys,
                    groupLabel: phase.name,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

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
