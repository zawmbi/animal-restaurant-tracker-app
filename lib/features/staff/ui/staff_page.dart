import 'package:flutter/material.dart';
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

  String _query = '';
  _StaffSortMode _sortMode = _StaffSortMode.jsonOrder;

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
          if (snap.connectionState != ConnectionState.done && snap.data == null) {
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

          // Sort (default = JSON order; alphabetical is optional)
          if (_sortMode == _StaffSortMode.alphabetical) {
            filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }

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
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, //  3 boxes per row
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return _StaffTile(
                      name: s.name,
                      series: s.series,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => StaffDetailPage(staff: s)),
                      ), blurb: '',
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

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.name,
    required this.series,
    required this.blurb,
    required this.onTap,
  });

  final String name;
  final String? series;
  final String? blurb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = (series ?? '').trim().isNotEmpty ? series!.trim() : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.badge_outlined, size: 22),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if ((blurb ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  blurb!.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
