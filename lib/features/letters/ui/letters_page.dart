import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/letters_repository.dart';
import '../model/letter.dart';
import '../../search/ui/global_search_page.dart';
import 'letter_detail_page.dart'; // ⬅️ add this

class LettersPage extends StatelessWidget {
  const LettersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;
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
                    final unlocked = store.isUnlocked('letter', l.id);
                    return EntityChip(
                      label: l.name,
                      checked: unlocked,
                      showCheckbox: true,
                      onCheckChanged: (v) =>
                          store.setUnlocked('letter', l.id, v),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LetterDetailPage(letter: l),
                          ),
                        );
                      },
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
