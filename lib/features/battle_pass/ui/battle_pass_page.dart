import 'package:flutter/material.dart';
import '../data/battle_pass_repository.dart';
import '../model/battle_pass.dart';
import 'battle_pass_detail_page.dart';

class BattlePassPage extends StatelessWidget {
  const BattlePassPage({super.key});

  Future<List<BattlePass>> _loadAll() async {
    final repo = BattlePassRepository.instance;

    final passes = await Future.wait<BattlePass>([
      repo.fantasticalParty(),
      repo.deepSeaBallad(),
      repo.slumberousNights(),
      repo.midsummerBirdsong(),
    ]);

    // Stable ordering for UI.
    passes.sort((a, b) => a.name.compareTo(b.name));
    return passes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Pass')),
      body: FutureBuilder<List<BattlePass>>(
        future: _loadAll(),
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: passes.length,
            itemBuilder: (context, i) {
              final pass = passes[i];

              final bits = <String>[
                if (pass.introducedInVersion.isNotEmpty)
                  'Introduced: ${pass.introducedInVersion}',
                if (pass.seasonDays > 0) 'Season length: ${pass.seasonDays} days',
                if (pass.phases.isNotEmpty) 'Phases: ${pass.phases.length}',
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    title: Text(
                      pass.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: bits.isEmpty ? null : Text(bits.join(' • ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BattlePassDetailPage(pass: pass),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
