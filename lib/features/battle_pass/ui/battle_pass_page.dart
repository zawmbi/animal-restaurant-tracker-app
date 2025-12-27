import 'package:flutter/material.dart';
import '../data/battle_pass_repository.dart';
import '../model/battle_pass.dart';
import 'battle_pass_detail_page.dart';

class BattlePassPage extends StatelessWidget {
  const BattlePassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Pass')),
      body: FutureBuilder<BattlePass>(
        future: BattlePassRepository.instance.fantasticalParty(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load battle pass:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final pass = snap.data;
          if (pass == null) return const Center(child: Text('No battle pass data.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(pass.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      if (pass.introducedInVersion.isNotEmpty)
                        'Introduced: ${pass.introducedInVersion}',
                      if (pass.seasonDays > 0) 'Season length: ${pass.seasonDays} days',
                      if (pass.phases.isNotEmpty) 'Phases: ${pass.phases.length}',
                    ].join(' • '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BattlePassDetailPage(pass: pass)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
