import 'package:flutter/material.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import 'dish_detail_page.dart';

/// Ranks buffet dishes by their cod-per-hour earnings — a quick "what should I
/// be serving" leaderboard.
class DishLeaderboardPage extends StatelessWidget {
  const DishLeaderboardPage({super.key});

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings Leaderboard')),
      body: FutureBuilder<List<Dish>>(
        future: DishesRepository.instance.all(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final ranked = (snap.data ?? const <Dish>[])
              .where((d) => (d.earningsPerHourInt ?? 0) > 0)
              .toList()
            ..sort((a, b) =>
                (b.earningsPerHourInt ?? 0).compareTo(a.earningsPerHourInt ?? 0));

          if (ranked.isEmpty) {
            return const Center(child: Text('No earnings data available.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Buffet dishes ranked by cod earned per hour.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: ranked.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = ranked[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${i + 1}'),
                      ),
                      title: Text(d.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/cod.png',
                              width: 18, height: 18),
                          const SizedBox(width: 4),
                          Text('${_fmt(d.earningsPerHourInt ?? 0)}/h',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DishDetailPage(dishId: d.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
