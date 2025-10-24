import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';

class DishDetailPage extends StatelessWidget {
  final String dishId;
  const DishDetailPage({super.key, required this.dishId});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;
    return FutureBuilder<Dish?>(
      future: DishesRepository.instance.byId(dishId),
      builder: (context, snap) {
        final dish = snap.data;
        final title = dish?.name ?? dishId;
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final unlocked = store.isUnlocked('dish', dishId);
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Unlocked'),
                      value: unlocked,
                      onChanged: (v) => store.setUnlocked('dish', dishId, v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    if (dish == null)
                      const Text('Dish not found in data yet.')
                    else ...[
                      Text('ID: ${dish.id}'),
                      if (dish.category != null)
                        Text('Category: ${dish.category}'),
                      const SizedBox(height: 12),
                      const Text('Add more dish stats here (price, unlocks…)'),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}