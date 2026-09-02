import 'package:flutter/material.dart';
import '../../completion/data/progress_types.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
import '../data/staff_repository.dart';
import '../model/staff_member.dart';
import 'staff_detail_page.dart';

enum _StaffSortMode { jsonOrder, alphabetical }

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _repo = StaffRepository.instance;
  final _store = UnlockedStore.instance;

  String _query = '';
  _StaffSortMode _sortMode = _StaffSortMode.jsonOrder;

  @override
  void initState() {
    super.initState();
    _store.registerType(ProgressTypes.staffUnlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          PopupMenuButton<_StaffSortMode>(
            tooltip: 'Sort',
            initialValue: _sortMode,
            onSelected: (v) => setState(() => _sortMode = v),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _StaffSortMode.jsonOrder,
                child: Text('Sort: JSON order'),
              ),
              PopupMenuItem(
                value: _StaffSortMode.alphabetical,
                child: Text('Sort: Alphabetical'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.sort),
                  const SizedBox(width: 6),
                  Text(
                    _sortMode == _StaffSortMode.jsonOrder ? 'JSON' : 'A–Z',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<StaffMember>>(
        future: _repo.all(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load staff.\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final list = snap.data ?? const <StaffMember>[];
          if (snap.connectionState != ConnectionState.done &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter
          final filtered = _query.trim().isEmpty
              ? List<StaffMember>.from(list)
              : list.where((s) {
                  final q = _query.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      (s.series ?? '').toLowerCase().contains(q);
                }).toList();

          // Default is the repository's source order, which is the wiki's
          // (and the game's) order. The repository used to alphabetise on
          // load, which silently defeated this option.
          if (_sortMode == _StaffSortMode.alphabetical) {
            filtered.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          }

          final ids = filtered.map((s) => s.id).toList();

          return AnimatedBuilder(
            animation: _store,
            builder: (context, _) {
              final unlocked = ids
                  .where(
                    (id) => _store.isUnlocked(ProgressTypes.staffUnlocked, id),
                  )
                  .length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search staff...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Unlocked: $unlocked/${ids.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        CheckAllButton(
                          bucket: ProgressTypes.staffUnlocked,
                          ids: ids,
                          groupLabel: 'Staff',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, cons) {
                        final crossAxisCount = (cons.maxWidth / 200)
                            .floor()
                            .clamp(1, 4);
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            // Name plus an optional series subtitle in a compact
                            // row, instead of a square tile of mostly empty space.
                            mainAxisExtent: 76,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            return _StaffTile(
                              name: s.name,
                              series: s.series,
                              unlocked: _store.isUnlocked(
                                ProgressTypes.staffUnlocked,
                                s.id,
                              ),
                              onUnlockedChanged: (v) => _store.setUnlocked(
                                ProgressTypes.staffUnlocked,
                                s.id,
                                v,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StaffDetailPage(staff: s),
                                ),
                              ),
                              blurb: '',
                            );
                          },
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

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.name,
    required this.series,
    required this.blurb,
    required this.onTap,
    required this.unlocked,
    required this.onUnlockedChanged,
  });

  final String name;
  final String? series;
  final String? blurb;
  final VoidCallback onTap;
  final bool unlocked;
  final ValueChanged<bool> onUnlockedChanged;

  @override
  Widget build(BuildContext context) {
    // The row fits one subtitle line, so series and blurb share it.
    final subtitle = [
      series,
      blurb,
    ].map((t) => (t ?? '').trim()).where((t) => t.isNotEmpty).join(' \u2022 ');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Checkbox(
                value: unlocked,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => onUnlockedChanged(v ?? false),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
