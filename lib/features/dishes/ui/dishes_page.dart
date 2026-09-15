import 'package:flutter/material.dart';
import '../../shared/widgets/check_all_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../shared/data/unlocked_store.dart';
import '../../search/ui/global_search_page.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import 'dish_detail_page.dart';
import 'dish_leaderboard_page.dart';
import '../../shared/widgets/search_field.dart';

class DishesPage extends StatefulWidget {
  const DishesPage({super.key});
  @override
  State<DishesPage> createState() => _DishesPageState();
}

class _DishesPageState extends State<DishesPage> {
  String _query = '';

  final repo = DishesRepository.instance;
  final store = UnlockedStore.instance; // bucket: 'dish'

  String _n(String s) => s.trim().toLowerCase();

  bool _inAnySection(Dish d, List<String> names) {
    final have = d.sections.map(_n).toSet();
    for (final n in names) {
      if (have.contains(_n(n))) return true;
    }
    return false;
  }

  bool _isFreshlyMade(Dish d) =>
      _inAnySection(d, ['Freshly Made', 'Fresh Dishes']);
  bool _isBuffet(Dish d) => _inAnySection(d, ['Buffet']);
  bool _isTakeout(Dish d) => _inAnySection(d, ['Takeout']);
  bool _isVegGarden(Dish d) =>
      _inAnySection(d, ['Vegetable Garden Recipes', 'Vegetable Garden']);

  Widget _unlockedCountRow(String label, int unlocked, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          '$unlocked / $total',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            tooltip: 'Earnings leaderboard',
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DishLeaderboardPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GlobalSearchPage())),
          ),
        ],
      ),
      body: FutureBuilder<List<Dish>>(
        future: repo.all(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load recipes:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final dishes = (snap.data ?? const <Dish>[])
              .where(
                (d) => matchesQuery(
                  _query,
                  '${d.name} ${d.id} ${d.description} ${d.sections.join(' ')}',
                ),
              )
              .toList();

          final freshlyMade = dishes.where(_isFreshlyMade).toList();
          final buffet = dishes.where(_isBuffet).toList();
          final takeout = dishes.where(_isTakeout).toList();
          final vegGarden = dishes.where(_isVegGarden).toList();

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              // Calculate unlocked counts for each category
              final unlockedAll = dishes
                  .where((d) => store.isUnlocked('dish', d.id))
                  .length;
              final unlockedFreshly = freshlyMade
                  .where((d) => store.isUnlocked('dish', d.id))
                  .length;
              final unlockedBuffet = buffet
                  .where((d) => store.isUnlocked('dish', d.id))
                  .length;
              final unlockedTakeout = takeout
                  .where((d) => store.isUnlocked('dish', d.id))
                  .length;
              final unlockedVegGarden = vegGarden
                  .where((d) => store.isUnlocked('dish', d.id))
                  .length;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    SearchField(
                      hintText: 'Search recipes…',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    // Unlocked counts header
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlocked Recipes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _unlockedCountRow('All', unlockedAll, dishes.length),
                          const SizedBox(height: 8),
                          _unlockedCountRow(
                            'Freshly Made',
                            unlockedFreshly,
                            freshlyMade.length,
                          ),
                          const SizedBox(height: 8),
                          _unlockedCountRow(
                            'Buffet',
                            unlockedBuffet,
                            buffet.length,
                          ),
                          const SizedBox(height: 8),
                          _unlockedCountRow(
                            'Takeout',
                            unlockedTakeout,
                            takeout.length,
                          ),
                          const SizedBox(height: 8),
                          _unlockedCountRow(
                            'Vegetable Garden',
                            unlockedVegGarden,
                            vegGarden.length,
                          ),
                        ],
                      ),
                    ),
                    _section(
                      context,
                      'All Recipes',
                      dishes,
                      showEvenIfEmpty: true,
                    ),
                    _section(
                      context,
                      'Freshly Made',
                      freshlyMade,
                      showEvenIfEmpty: true,
                    ),
                    _section(context, 'Buffet', buffet, showEvenIfEmpty: true),
                    _section(
                      context,
                      'Takeout',
                      takeout,
                      showEvenIfEmpty: true,
                    ),
                    _section(
                      context,
                      'Vegetable Garden Recipes',
                      vegGarden,
                      showEvenIfEmpty: true,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Dish> list, {
    bool showEvenIfEmpty = false,
  }) {
    if (list.isEmpty && !showEvenIfEmpty) return const SizedBox.shrink();

    final ids = list.map((d) => d.id).toList();

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          CheckAllButton(
            bucket: 'dish',
            ids: ids,
            groupLabel: title,
          ),
        ],
      ),
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No recipes in this section yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, cons) {
                // 180, not 200: a tile holds a name and a checkbox, and
                // at 200 the arithmetic gives (366 / 200).floor() == 1, so
                // every phone got one column of half-empty rows. 180 gives a
                // 390pt phone 2 columns and an iPad still gets 4.
                final crossAxisCount = (cons.maxWidth / 180).floor().clamp(
                  1,
                  4,
                );
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    // A tile holds only a name and a checkbox, so give it a
                    // fixed row height instead of forcing it square.
                    mainAxisExtent: 56,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    final checked = store.isUnlocked('dish', d.id);
                    return _RecipeTile(
                      label: d.name,
                      isUnlocked: checked,
                      onCheckChanged: (v) => store.setUnlocked('dish', d.id, v),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DishDetailPage(dishId: d.id),
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
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.label,
    required this.isUnlocked,
    required this.onCheckChanged,
    required this.onTap,
  });

  final String label;
  final bool isUnlocked;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Expanded(
                child: AutoSizeText(
                  label,
                  maxLines: 2,
                  wrapWords: true,
                  minFontSize: 10,
                  stepGranularity: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: isUnlocked,
                  onChanged: (v) => onCheckChanged(v ?? false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
