import 'package:flutter/material.dart';
import '../data/pets_repository.dart';
import '../data/pet_progress.dart';
import '../model/pet.dart';
import 'pet_detail_page.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final progress = PetProgress.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pets')),
      body: FutureBuilder<PetsData>(
        future: PetsRepository.instance.load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          final pets = data.pets;

          final ownedCount =
              pets.where((p) => progress.isOwned(p.id)).length;
          final matureCount =
              pets.where((p) => progress.isMature(p.id)).length;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlocking',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Requires Rating ${data.ratingRequired.toString()} (added in v${data.updatedInVersion})',
                      ),
                      if (data.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(data.notes),
                      ],
                      const Divider(height: 20),
                      Text('Owned: $ownedCount / ${pets.length}'),
                      Text('Mature: $matureCount / ${pets.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              ...pets.map((p) {
                final owned = progress.isOwned(p.id);
                final mature = progress.isMature(p.id);

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PetDetailPage(pet: p),
                      ),
                    ).then((_) => setState(() {})),
                    child: ListTile(
                      title: Text(p.nickname),
                      subtitle: Text(
                        'Series ${p.series.join(' & ')} • ${p.hatchlingName} → ${p.matureName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Owned', style: TextStyle(fontSize: 12)),
                              Checkbox(
                                value: owned,
                                onChanged: (v) async {
                                  await progress.setOwned(p.id, v ?? false);
                                  if (!(v ?? false)) {
                                    // If you un-own a pet, also clear Mature so states never contradict.
                                    await progress.setMature(p.id, false);
                                  }
                                  if (!mounted) return;
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Mature', style: TextStyle(fontSize: 12)),
                              Checkbox(
                                value: mature,
                                onChanged: owned
                                    ? (v) async {
                                        await progress.setMature(p.id, v ?? false);
                                        if (!mounted) return;
                                        setState(() {});
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  title: const Text('Pet Rooms & Photo Tasks'),
                  subtitle: Text('Added in v${data.petRoomsUpdatedInVersion}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PetRoomsAndPhotosPage(data: data),
                    ),
                  ).then((_) => setState(() {})),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PetRoomsAndPhotosPage extends StatefulWidget {
  final PetsData data;
  const _PetRoomsAndPhotosPage({required this.data});

  @override
  State<_PetRoomsAndPhotosPage> createState() => _PetRoomsAndPhotosPageState();
}

class _PetRoomsAndPhotosPageState extends State<_PetRoomsAndPhotosPage> {
  final progress = PetProgress.instance;

  @override
  Widget build(BuildContext context) {
    final rooms = widget.data.rooms;
    final tasks = widget.data.photoTasks;

    final roomIds = rooms.map((e) => e.id).toList();
    final taskIds = tasks.map((e) => e.id).toList();

    final unlockedRooms =
        rooms.where((r) => progress.isRoomUnlocked(r.id)).length;
    final doneTasks =
        tasks.where((t) => progress.isPhotoTaskDone(t.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Rooms & Photo Tasks')),
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
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('Rooms unlocked: $unlockedRooms / ${rooms.length}'),
                  Text('Photo tasks done: $doneTasks / ${tasks.length}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await progress.setAllRooms(true, roomIds);
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Mark all rooms'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await progress.setAllRooms(false, roomIds);
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Clear all rooms'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await progress.setAllPhotoTasks(true, taskIds);
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Mark all photos'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await progress.setAllPhotoTasks(false, taskIds);
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Clear all photos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text('Rooms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),

          ...rooms.map((r) {
            final v = progress.isRoomUnlocked(r.id);
            final price = r.amount == 0 ? 'Free' : '${r.currency}${r.amount.toString()}';
            final req = r.requiresPets == 0 ? '' : ' • Needs ${r.requiresPets} pets';

            return Card(
              child: ListTile(
                title: Text(r.name),
                subtitle: Text('$price$req'),
                trailing: Checkbox(
                  value: v,
                  onChanged: (nv) async {
                    await progress.setRoomUnlocked(r.id, nv ?? false);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 14),
          Text('Photo Tasks', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),

          ...tasks.map((t) {
            final v = progress.isPhotoTaskDone(t.id);

            String rewardsText = t.rewards.map((r) {
              if (r.currency != null) return '${r.currency}${r.amount}';
              if (r.item != null) return '${r.item} x${r.amount}';
              return '';
            }).where((s) => s.isNotEmpty).join(' • ');

            return Card(
              child: ListTile(
                title: Text('Pets: ${t.pets.join(' + ')}'),
                subtitle: Text(
                  'Furniture: ${t.furniture.join(', ')}\nRewards: $rewardsText',
                ),
                isThreeLine: true,
                trailing: Checkbox(
                  value: v,
                  onChanged: (nv) async {
                    await progress.setPhotoTaskDone(t.id, nv ?? false);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
