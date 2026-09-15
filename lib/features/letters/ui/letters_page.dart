import 'package:flutter/material.dart';
import '../../shared/widgets/check_all_button.dart';

import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../../search/ui/global_search_page.dart';

import '../data/letters_repository.dart';
import '../model/letter.dart';
import 'letter_detail_page.dart';
import '../../shared/widgets/search_field.dart';

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});

  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  final store = UnlockedStore.instance;

  static const String _bucketLetter = 'letter';
  String _query = '';


  @override
  void initState() {
    super.initState();
    store.registerType(_bucketLetter);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Letter>>(
        future: LettersRepository.instance.all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final list = all
              .where((l) => matchesQuery(
                    _query,
                    '${l.name} ${l.id} ${l.series ?? ''} '
                    '${l.description ?? ''} ${l.unlockRequirement ?? ''}',
                  ))
              .toList();

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final ownedCount =
                  list.where((l) => store.isUnlocked(_bucketLetter, l.id)).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    hintText: 'Search letters…',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Owned: $ownedCount/${list.length}',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        CheckAllButton(
                          bucket: _bucketLetter,
                          ids: list.map((l) => l.id).toList(),
                          groupLabel: 'Letters',
                        ),
                      ],
                    ),
                  ),
                  // A Wrap of 257 pills sized to their own labels. Letter
                  // names average 21 characters, so two chips rarely fit on
                  // one 366pt row — it packed about 1.2 per row and left the
                  // rest of each row blank. A fixed grid gets a true two
                  // columns, and builds lazily instead of laying out all 257
                  // chips on every keystroke and every checkbox tap.
                  Expanded(
                    child: LayoutBuilder(
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
                            final l = list[i];
                            final owned =
                                store.isUnlocked(_bucketLetter, l.id);

                            return EntityChip(
                              label: l.name,
                              checked: owned,
                              showCheckbox: true,
                              // Names run to 50 characters; shrink to fit the
                              // cell rather than spilling out of it.
                              maxLines: 2,
                              onCheckChanged: (v) =>
                                  store.setUnlocked(_bucketLetter, l.id, v),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        LetterDetailPage(letter: l)),
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
