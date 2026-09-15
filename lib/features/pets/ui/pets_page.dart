import 'package:flutter/material.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/widgets/check_all_button.dart';
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

          final petIds = pets.map((p) => p.id).toList();
          final ownedCount = pets.where((p) => progress.isOwned(p.id)).length;
          final matureCount = pets.where((p) => progress.isMature(p.id)).length;

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
                        'Requires Rating ${data.ratingRequired} (added in v${data.updatedInVersion})',
                      ),
                      if (data.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(data.notes),
                      ],
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Owned: $ownedCount / ${pets.length}'),
                          ),
                          CheckAllButton(
                            bucket: ProgressTypes.petOwned,
                            ids: petIds,
                            groupLabel: 'Pets owned',
                            onApplied: (_) async {
                              // A pet cannot be mature if it is not owned.
                              // Read the store rather than the flag: "Undo
                              // check all" leaves the pets the player had
                              // already ticked owned, and those keep their
                              // maturity.
                              final notOwned = <String>[
                                for (final id in petIds)
                                  if (!progress.isOwned(id)) id,
                              ];
                              if (notOwned.isNotEmpty) {
                                await progress.setAllMature(false, notOwned);
                              }
                              if (!mounted) return;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mature: $matureCount / ${pets.length}',
                            ),
                          ),
                          CheckAllButton(
                            bucket: ProgressTypes.petMature,
                            ids: petIds,
                            groupLabel: 'Pets matured',
                            onApplied: (_) async {
                              // Marking a pet mature implies owning it, so
                              // every pet that now reads mature must read
                              // owned — including after an undo, which leaves
                              // some of them mature.
                              final mature = <String>[
                                for (final id in petIds)
                                  if (progress.isMature(id)) id,
                              ];
                              if (mature.isNotEmpty) {
                                await progress.setAllOwned(true, mature);
                              }
                              if (!mounted) return;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
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
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => PetDetailPage(pet: p),
                          ),
                        )
                        .then((_) => setState(() {})),
                    child: ListTile(
                      title: Text(p.nickname),
                      // This string measures 39-51 characters for all 17
                      // pets against ~34 characters of room, so at maxLines: 2
                      // every single row wrapped and took the 88pt three-line
                      // tile. One line puts them all back on the 72pt one.
                      subtitle: Text(
                        'Series ${p.series.join(' & ')} • ${p.hatchlingName} → ${p.matureName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      //  trailing can only be ~48px tall.
                      // Remove vertical Columns with label text.
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Owned',
                            child: Checkbox(
                              value: owned,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) async {
                                final nv = v ?? false;
                                await progress.setOwned(p.id, nv);
                                if (!nv) {
                                  await progress.setMature(p.id, false);
                                }
                                if (!mounted) return;
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Mature',
                            child: Checkbox(
                              value: mature,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: owned
                                  ? (v) async {
                                      await progress.setMature(
                                        p.id,
                                        v ?? false,
                                      );
                                      if (!mounted) return;
                                      setState(() {});
                                    }
                                  : null,
                            ),
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
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => _PetRoomsAndPhotosPage(data: data),
                        ),
                      )
                      .then((_) => setState(() {})),
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

  static const Map<String, String> _currencyIcon = {
    'cod': 'assets/images/cod.png',
    'film': 'assets/images/film.png',
    'bell': 'assets/images/bell.png',
    'plates': 'assets/images/plate.png',
    'diamonds': 'assets/images/diamond.png',
  };

  Widget _currencyPill(String currency, int amount) {
    final path = _currencyIcon[currency.toLowerCase()];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (path != null)
          Image.asset(path, width: 18, height: 18)
        else
          const Icon(Icons.monetization_on, size: 18),
        const SizedBox(width: 6),
        Text(amount.toString()),
      ],
    );
  }

  Widget _rewardLine(PetPhotoTaskReward r) {
    if (r.currency != null && r.amount != null) {
      return _currencyPill(r.currency!, r.amount!);
    }
    if (r.item != null && r.amount != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 18),
          const SizedBox(width: 6),
          Text('${r.item} x${r.amount}'),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.data.rooms;
    final tasks = widget.data.photoTasks;

    final roomIds = rooms.map((e) => e.id).toList();
    final taskIds = tasks.map((e) => e.id).toList();

    final unlockedRooms = rooms
        .where((r) => progress.isRoomUnlocked(r.id))
        .length;
    final doneTasks = tasks.where((t) => progress.isPhotoTaskDone(t.id)).length;

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
                          if (unlockedRooms > 0) {
                            final ok = await CheckAllButton.confirmUncheck(
                              context,
                              count: unlockedRooms,
                              groupLabel: 'Pet Rooms',
                            );
                            if (!ok) return;
                          }
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
                          if (doneTasks > 0) {
                            final ok = await CheckAllButton.confirmUncheck(
                              context,
                              count: doneTasks,
                              groupLabel: 'Photo Tasks',
                            );
                            if (!ok) return;
                          }
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
            final req = r.requiresPets == 0
                ? ''
                : ' • Needs ${r.requiresPets} pets';

            return Card(
              child: ListTile(
                title: Text(r.name),
                subtitle: Row(
                  children: [
                    if (r.amount == 0)
                      const Text('Free')
                    else
                      _currencyPill(r.currency, r.amount),
                    if (req.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          req.trim(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
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

            return Card(
              child: ListTile(
                title: Text('Pets: ${t.pets.join(' + ')}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Furniture: ${t.furniture.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: t.rewards.map(_rewardLine).toList(),
                    ),
                  ],
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
