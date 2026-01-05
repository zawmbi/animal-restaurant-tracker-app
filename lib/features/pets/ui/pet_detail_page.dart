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

  Future<void> _setOwned(bool v) async {
    await progress.setOwned(p.id, v);
    if (!v) {
      await progress.setMature(p.id, false);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _setMature(bool v) async {
    await progress.setMature(p.id, v);
    if (!mounted) return;
    setState(() {});
  }

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
                  if (p.likes.isNotEmpty) Text('Likes: ${p.likes.join(', ')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Owned / Hatched'),
                  subtitle: const Text('Track whether you have this pet.'),
                  trailing: Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: owned,
                      onChanged: _setOwned,
                    ),
                  ),
                  onTap: () => _setOwned(!owned),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Mature'),
                  subtitle: const Text('Only enabled if Owned is on.'),
                  enabled: owned,
                  trailing: Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: mature,
                      onChanged: owned ? _setMature : null,
                    ),
                  ),
                  onTap: owned ? () => _setMature(!mature) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
