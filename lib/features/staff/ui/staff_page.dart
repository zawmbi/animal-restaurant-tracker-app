import 'package:flutter/material.dart';
import '../data/staff_repository.dart';
import '../model/staff_member.dart';
import 'staff_detail_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _repo = StaffRepository.instance;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
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

          final filtered = _query.trim().isEmpty
              ? list
              : list.where((s) {
                  final q = _query.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      (s.series ?? '').toLowerCase().contains(q);
                }).toList();

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
                child: snap.connectionState != ConnectionState.done && snap.data == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final s = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StaffDetailPage(staff: s),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.name,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          if ((s.series ?? '').trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                s.series!,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ),
                                          if ((s.blurb ?? '').trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                s.blurb!,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
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
      ),
    );
  }
}
