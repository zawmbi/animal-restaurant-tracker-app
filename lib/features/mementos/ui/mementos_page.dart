import 'package:flutter/material.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/mementos_index.dart';
import 'mementos_detail_page.dart';


class MementosPage extends StatefulWidget {
  const MementosPage({super.key});

  /// Tag chips, each of which must be a tag mementos.json actually carries.
  ///
  /// 'hidden' used to be listed here and matched nothing: hidden is a
  /// top-level field, not a tag, so the chip filtered 1,184 mementos down to
  /// none. The "Hidden" dropdown next to these chips reads the real field.
  ///
  /// Public so a test can check every chip still matches something —
  /// see test/models/model_parsing_test.dart.
  static const List<String> commonTags = <String>[
    'customer_gift',
    'redemption_code',
    'wishing_well',
    'gachapon',
    'poster',
  ];

  @override
  State<MementosPage> createState() => _MementosPageState();
}

class _MementosPageState extends State<MementosPage> {
  final store = UnlockedStore.instance;
  final _searchCtrl = TextEditingController();
  final Set<String> _tags = {};
  bool? _hidden; // null=all, true=hidden only, false=not hidden

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
    List<MementoEntry> all,
    _MementoCategory category,
  ) {
    final filtered = all.where((e) {
      final isPoster = e.tags.contains('poster');
      final isDressUp = e.isWearable;

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

    final ids = filtered.map((e) => e.key).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length + 1,
      itemBuilder: (context, rawIndex) {
        if (rawIndex == 0) {
          return Align(
            alignment: Alignment.centerRight,
            child: CheckAllButton(
              bucket: 'memento_collected',
              ids: ids,
              groupLabel: 'Mementos',
            ),
          );
        }
        final index = rawIndex - 1;
        final e = filtered[index];
        final collected = store.isUnlocked('memento_collected', e.key);
        String subtitle = [
          if (e.customerName != null && e.customerName!.isNotEmpty)
            e.customerName!,
          if (e.source != null && e.source!.isNotEmpty) e.source!,
          if (e.event != null && e.event!.isNotEmpty) e.event!,
          if (e.tags.contains('poster')) 'Poster',
          if (e.isWearable) 'Dress-Up',
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
            for (final t in MementosPage.commonTags)
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
