import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/mementos_index.dart';
import 'mementos_detail_page.dart';


class MementosPage extends StatefulWidget {
  const MementosPage({super.key});

  @override
  State<MementosPage> createState() => _MementosPageState();
}

class _MementosPageState extends State<MementosPage> {
  final store = UnlockedStore.instance;
  final _searchCtrl = TextEditingController();
  final Set<String> _tags = {};
  bool? _hidden; // null=all, true=hidden only, false=not hidden

  final List<String> commonTags = const [
    'customer_gift',
    'redemption_code',
    'wishing_well',
    'gachapon',
    'poster',
    'hidden',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mementos'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'ALL'),
              Tab(text: 'Mementos'),
              Tab(text: 'Dress-Up'),
              Tab(text: 'Poster'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return FutureBuilder(
              future: MementosIndex.instance.all(
                includeTags: _tags.isEmpty ? null : _tags.toList(),
                search: _searchCtrl.text,
                hidden: _hidden,
              ),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!; // List<MementoInfo> (or whatever your type is)

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _filters(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildMementoList(context, list, _MementoCategory.all),
                          _buildMementoList(context, list, _MementoCategory.mementos),
                          _buildMementoList(context, list, _MementoCategory.dressUp),
                          _buildMementoList(context, list, _MementoCategory.poster),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMementoList(
    BuildContext context,
    List<dynamic> all, // replace dynamic with your concrete memento type
    _MementoCategory category,
  ) {
    final filtered = all.where((e) {
      final tags = (e.tags ?? const <String>[]).cast<String>();
      final isPoster = tags.contains('poster');
      final isDressUp = tags.contains('dress_up') || tags.contains('wearable');

      switch (category) {
        case _MementoCategory.all:
          return true;
        case _MementoCategory.mementos:
          // regular mementos = NOT dress-up and NOT poster
          return !isPoster && !isDressUp;
        case _MementoCategory.dressUp:
          return isDressUp;
        case _MementoCategory.poster:
          return isPoster;
      }
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No mementos match your filters.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final e = filtered[index];
        final collected = store.isUnlocked('memento_collected', e.key);
        final tags = (e.tags ?? const <String>[]).cast<String>();

        String subtitle = [
          if (e.customerName != null && e.customerName!.isNotEmpty) e.customerName!,
          if (e.source != null && e.source!.isNotEmpty) e.source!,
          if (e.event != null && e.event!.isNotEmpty) e.event!,
          if (tags.contains('poster')) 'Poster',
          if (tags.contains('dress_up') || tags.contains('wearable')) 'Dress-Up',
        ].join(' • ');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            // NO MORE CircleAvatar / star here
            title: Text(e.name),
            subtitle: subtitle.isEmpty ? null : Text(subtitle),
            trailing: Checkbox(
              value: collected,
              onChanged: (v) => store.setUnlocked('memento_collected', e.key, v ?? false),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MementoDetailPage(memento: e),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search name, description, or customer…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in commonTags)
              FilterChip(
                label: Text(t.replaceAll('_', ' ')),
                selected: _tags.contains(t),
                onSelected: (sel) {
                  setState(() {
                    sel ? _tags.add(t) : _tags.remove(t);
                  });
                },
              ),
            const SizedBox(width: 12),
            DropdownButton<bool?>(
              value: _hidden,
              items: const [
                DropdownMenuItem(value: null, child: Text('All visibility')),
                DropdownMenuItem(value: false, child: Text('Not hidden')),
                DropdownMenuItem(value: true, child: Text('Hidden only')),
              ],
              onChanged: (v) => setState(() => _hidden = v),
            ),
          ],
        ),
      ],
    );
  }
}

enum _MementoCategory { all, mementos, dressUp, poster }
