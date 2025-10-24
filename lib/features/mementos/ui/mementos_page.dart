import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/mementos_index.dart';

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
    'customer_gift','redemption_code','wishing_well','gachapon','poster','hidden'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mementos')),
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
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!;
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _filters(),
                  const SizedBox(height: 8),
                  ...list.map((e) {
                    final collected = store.isUnlocked('memento_collected', e.key);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('+${e.stars}')),
                        title: Text(e.name),
                        subtitle: Text([
                          if (e.customerName != null) e.customerName!,
                          if (e.source != null) e.source!,
                          if (e.event != null) e.event!,
                        ].join(' • ')),
                        trailing: Checkbox(
                          value: collected,
                          onChanged: (v) => store.setUnlocked('memento_collected', e.key, v ?? false),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
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
              onPressed: () { _searchCtrl.clear(); setState(() {}); },
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
                onSelected: (sel) => setState(() {
                  sel ? _tags.add(t) : _tags.remove(t);
                }),
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