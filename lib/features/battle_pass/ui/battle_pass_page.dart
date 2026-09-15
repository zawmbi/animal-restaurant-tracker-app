import 'package:flutter/material.dart';
import '../../completion/data/completion_service.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
import '../data/battle_pass_repository.dart';
import '../model/battle_pass.dart';
import 'battle_pass_detail_page.dart';

/// Every claim key for a pass. The Super track only exists once you own that
/// pass's premium tier, so it is only included when you do — this matches how
/// BattlePassDetailPage decides whether a tier counts as claimed.
List<String> battlePassClaimKeys(BattlePass pass, UnlockedStore store) {
  final premium = store.isUnlocked(ProgressTypes.battlePassPremium, pass.id);
  final keys = <String>[];
  for (final phase in pass.phases) {
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
  }
  return keys;
}

class BattlePassPage extends StatefulWidget {
  const BattlePassPage({super.key});

  @override
  State<BattlePassPage> createState() => _BattlePassPageState();
}

class _BattlePassPageState extends State<BattlePassPage> {
  final store = UnlockedStore.instance;
  late final Future<List<BattlePass>> _future;

  @override
  void initState() {
    super.initState();
    // Claims live outside UnlockedStore's default types, so register them
    // before the first read.
    store.registerType(ProgressTypes.battlePassClaimed);
    store.registerType(ProgressTypes.battlePassPremium);
    store.registerType(ProgressTypes.battlePassPlayed);
    _future = _loadAll();
  }

  Future<List<BattlePass>> _loadAll() async {
    final repo = BattlePassRepository.instance;

    final passes = await Future.wait<BattlePass>([
      repo.fantasticalParty(),
      repo.deepSeaBallad(),
      repo.slumberousNights(),
      repo.midsummerBirdsong(),
    ]);

    // Listed in the order they were fetched above, which is release order.
    // Alphabetising them put unrelated seasons next to each other.
    return passes;
  }

  int _claimedCount(List<String> keys) {
    var n = 0;
    for (final k in keys) {
      if (store.isUnlocked(ProgressTypes.battlePassClaimed, k)) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Pass')),
      body: FutureBuilder<List<BattlePass>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load battle passes:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final passes = snap.data ?? const <BattlePass>[];
          if (passes.isEmpty) {
            return const Center(child: Text('No battle pass data.'));
          }

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final allKeys = <String>[];
              for (final p in passes) {
                allKeys.addAll(battlePassClaimKeys(p, store));
              }
              final claimedAll = _claimedCount(allKeys);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Claimed: $claimedAll/${allKeys.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        CheckAllButton(
                          bucket: ProgressTypes.battlePassClaimed,
                          ids: allKeys,
                          groupLabel: 'Battle Pass rewards',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: passes.length,
                      itemBuilder: (context, i) {
                        final pass = passes[i];
                        final keys = battlePassClaimKeys(pass, store);
                        final claimed = _claimedCount(keys);
                        final played = store.isUnlocked(
                            ProgressTypes.battlePassPlayed, pass.id);

                        final bits = <String>[
                          if (pass.introducedInVersion.isNotEmpty)
                            'Introduced: ${pass.introducedInVersion}',
                          if (pass.seasonDays > 0)
                            'Season length: ${pass.seasonDays} days',
                          if (pass.phases.isNotEmpty)
                            'Phases: ${pass.phases.length}',
                          'Claimed: $claimed/${keys.length}',
                          if (!played) 'not counted — tick if you played it',
                        ];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                pass.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle:
                                  bits.isEmpty ? null : Text(bits.join(' • ')),
                              // Three of the four passes are expired events.
                              // Ticking this is what puts a pass into the
                              // completion total, so someone who was not
                              // there is not held to tiers they can never
                              // claim.
                              leading: Tooltip(
                                message: 'I took part in this pass',
                                child: Checkbox(
                                  value: played,
                                  onChanged: (v) => store.setUnlocked(
                                    ProgressTypes.battlePassPlayed,
                                    pass.id,
                                    v ?? false,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CheckAllButton(
                                    bucket: ProgressTypes.battlePassClaimed,
                                    ids: keys,
                                    groupLabel: pass.name,
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BattlePassDetailPage(pass: pass),
                                ),
                              ),
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
