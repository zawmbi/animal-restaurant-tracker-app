import 'package:flutter/material.dart';

import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../../search/ui/global_search_page.dart';

import '../data/letters_repository.dart';
import '../model/letter.dart';
import 'letter_detail_page.dart';

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});

  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  final store = UnlockedStore.instance;

  static const String _bucketLetter = 'letter';

  Color _ownedFill(BuildContext context) => Colors.green.withOpacity(0.18);

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketLetter);
  }

  @override
  Widget build(BuildContext context) {
    final ownedFill = _ownedFill(context);

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
          final list = snap.data!;

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map((l) {
                    final owned = store.isUnlocked(_bucketLetter, l.id);

                    return EntityChip(
                      label: l.name,
                      checked: owned,
                      showCheckbox: true,
                      fillColor: owned ? ownedFill : null,
                      onCheckChanged: (v) => store.setUnlocked(_bucketLetter, l.id, v),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LetterDetailPage(letter: l)),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
