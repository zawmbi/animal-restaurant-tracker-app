import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import 'dish_detail_page.dart';
import '../../search/ui/global_search_page.dart';

class DishesPage extends StatelessWidget {
  const DishesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance; // use 'dish' bucket
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Dish>>(
        future: DishesRepository.instance.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final dishes = snap.data!;
          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: dishes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, i) {
                    final d = dishes[i];
                    final checked = store.isUnlocked('dish', d.id);
                    return EntityChip(
                      label: d.name,
                      checked: checked,
                      showCheckbox: true,
                      onCheckChanged: (v) => store.setUnlocked('dish', d.id, v!),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DishDetailPage(dishId: d.id)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}