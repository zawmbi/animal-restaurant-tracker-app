import 'package:flutter/material.dart';
import '../data/pet_progress.dart';
import '../model/pet.dart';

class PetDetailPage extends StatefulWidget {
  final Pet pet;
  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  final progress = PetProgress.instance;

  Pet get p => widget.pet;

  @override
  Widget build(BuildContext context) {
    final owned = progress.isOwned(p.id);
    final mature = progress.isMature(p.id);

    return Scaffold(
      appBar: AppBar(title: Text(p.nickname)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nickname,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text('Hatchling: ${p.hatchlingName}'),
                  Text('Mature: ${p.matureName}'),
                  Text('Series: ${p.series.join(' & ')}'),
                  const SizedBox(height: 8),
                  if (p.likes.isNotEmpty)
                    Text('Likes: ${p.likes.join(', ')}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Owned / Hatched'),
                  subtitle: const Text('Track whether you have this pet.'),
                  value: owned,
                  onChanged: (v) async {
                    await progress.setOwned(p.id, v);
                    if (!v) {
                      await progress.setMature(p.id, false);
                    }
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Mature'),
                  subtitle: const Text('Only enabled if Owned is on.'),
                  value: mature,
                  onChanged: owned
                      ? (v) async {
                          await progress.setMature(p.id, v);
                          if (!mounted) return;
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Note: This tracker intentionally does not include repeatable goals (e.g., weekly tasks) or temporary event tasks.\n'
                'This page only tracks stable progress you can “finish” (like owning/maturing pets, rooms, and photo tasks).',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
