// lib/features/customers/ui/posters_page.dart

import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/widgets/search_field.dart';
import '../data/posters_repository.dart';
import '../model/poster.dart';
import 'poster_detail_page.dart';

/// The list of every poster.
///
/// All 155 posters were already counted toward overall completion, but only
/// six could ever be ticked: `PosterDetailPage` was reachable from exactly one
/// place — a performer's `posterIds` on the customer page — and exactly one of
/// the 613 customers carries any. So 149 posters were permanently unowned and
/// the headline percentage was capped at 98% no matter how the game went.
class PostersPage extends StatefulWidget {
  const PostersPage({super.key});

  @override
  State<PostersPage> createState() => _PostersPageState();
}

class _PostersPageState extends State<PostersPage> {
  static const String _bucket = 'poster';

  final store = UnlockedStore.instance;
  final _future = PostersRepository.instance.all();
  String _query = '';

  @override
  void initState() {
    super.initState();
    store.registerType(_bucket);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posters')),
      body: FutureBuilder<List<Poster>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data!;
          final list = all.where((p) {
            if (_query.trim().isEmpty) return true;
            final q = _query.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q);
          }).toList();

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final owned =
                  list.where((p) => store.isUnlocked(_bucket, p.id)).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    hintText: 'Search posters…',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Owned: $owned/${list.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        CheckAllButton(
                          bucket: _bucket,
                          ids: list.map((p) => p.id).toList(),
                          groupLabel: 'Posters',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('No posters match that.'))
                        : LayoutBuilder(
                            builder: (context, cons) {
                              final crossAxisCount =
                                  (cons.maxWidth / 180).floor().clamp(1, 4);
                              return GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  mainAxisExtent: 56,
                                ),
                                itemCount: list.length,
                                itemBuilder: (context, i) {
                                  final p = list[i];
                                  final checked =
                                      store.isUnlocked(_bucket, p.id);
                                  return EntityChip(
                                    label: p.name,
                                    checked: checked,
                                    showCheckbox: true,
                                    maxLines: 2,
                                    onCheckChanged: (v) =>
                                        store.setUnlocked(_bucket, p.id, v),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PosterDetailPage(posterId: p.id),
                                      ),
                                    ),
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
