import 'package:flutter/material.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import '../../shared/data/unlocked_store.dart';

class DishDetailPage extends StatelessWidget {
  const DishDetailPage({super.key, required this.dishId});

  final String dishId;

  @override
  Widget build(BuildContext context) {
    final repo = DishesRepository.instance;
    final store = UnlockedStore.instance; // bucket: 'dish'

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe details')),
      body: FutureBuilder<Dish?> (
        future: repo.byId(dishId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load dish:\n${snap.error}', textAlign: TextAlign.center),
            );
          }

          final dish = snap.data;
          if (dish == null) return const Center(child: Text('Dish not found'));

          return _DishDetailBody(dish: dish, store: store);
        },
      ),
    );
  }
}

class _DishDetailBody extends StatelessWidget {
  const _DishDetailBody({required this.dish, required this.store});

  final Dish dish;
  final UnlockedStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final checked = store.isUnlocked('dish', dish.id);
        final cat = _inferCategory(dish);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    dish.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Checkbox(
                  value: checked,
                  onChanged: (v) => store.setUnlocked('dish', dish.id, v ?? false),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (dish.sections.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dish.sections.map((s) => Chip(label: Text(s))).toList(),
              ),

            if (dish.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(dish.description),
            ],

            const SizedBox(height: 16),
            _categoryCard(context, cat, dish),
          ],
        );
      },
    );
  }

  Widget _categoryCard(BuildContext context, DishCategory cat, Dish d) {
    final title = () {
      switch (cat) {
        case DishCategory.freshlyMade: return 'Freshly Made';
        case DishCategory.buffet: return 'Buffet';
        case DishCategory.takeout: return 'Takeout';
        case DishCategory.vegGarden: return 'Vegetable Garden Recipes';
        case DishCategory.foodTruck: return 'Food Truck Recipe';
        case DishCategory.unknown: return 'Recipe';
      }
    }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(cat)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            ..._buildFieldsForCategory(cat, d),

            if (d.refinedRating != null || (d.ingredients?.isNotEmpty ?? false) || d.perfectDishes != null || d.prepTimeSeconds != null || (d.flavor?.isNotEmpty ?? false))
              const Divider(height: 24),
            if (d.refinedRating != null) _kv('Refined Rating', d.refinedRating!.toString()),
            if (d.perfectDishes != null) _kv('Perfect Dishes', d.perfectDishes!.toString()),
            if (d.prepTimeSeconds != null) _kv('Prep Time', _secondsToString(d.prepTimeSeconds!)),
            if ((d.flavor?.isNotEmpty ?? false)) _kv('Flavor', d.flavor!),
            if ((d.ingredients?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _formatIngredients(d.ingredients!).map((e) => Chip(label: Text(e))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForCategory(DishCategory cat, Dish d) {
    final widgets = <Widget>[];
    void addKV(String k, String? v) {
      if (v == null || v.isEmpty) return;
      widgets.add(_kv(k, v));
    }

    switch (cat) {
      case DishCategory.freshlyMade:
        addKV('Time', d.timeSeconds != null ? _secondsToString(d.timeSeconds!) : null);
        addKV('Earnings (Max)', d.earningsMax != null ? _formatInt(d.earningsMax!) : null);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
      case DishCategory.buffet:
        addKV('Earnings', d.earningsPerHour);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
      case DishCategory.takeout:
        addKV('Earnings', d.earningsRange);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
      case DishCategory.vegGarden:
        addKV('Time', d.timeSeconds != null ? _secondsToString(d.timeSeconds!) : null);
        addKV('Earnings (Max)', d.earningsMax != null ? _formatInt(d.earningsMax!) : null);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
      case DishCategory.foodTruck:
        addKV('Time', d.timeSeconds != null ? _secondsToString(d.timeSeconds!) : (d.prepTimeSeconds != null ? _secondsToString(d.prepTimeSeconds!) : null));
        addKV('Earnings (Max)', d.earningsMax != null ? _formatInt(d.earningsMax!) : null);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
      case DishCategory.unknown:
        addKV('Time', d.timeSeconds != null ? _secondsToString(d.timeSeconds!) : null);
        addKV('Earnings (Max)', d.earningsMax != null ? _formatInt(d.earningsMax!) : null);
        addKV('Earnings', d.earningsPerHour ?? d.earningsRange);
        addKV('Requirement', d.requirement);
        addKV('Cost', _formatCost(d.costText));
        break;
    }
    return widgets;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _formatInt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static String _secondsToString(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  static String _formatCost(String? costText) {
    if (costText == null || costText.isEmpty) return '—';
    return costText;
  }

  static List<String> _formatIngredients(String raw) {
    // Accepts "Wheat (4); Rice (3)" and line breaks
    final semi = raw.split(';');
    final parts = <String>[];
    for (final p in semi) {
      for (final q in p.split('\n')) {
        final t = q.trim();
        if (t.isNotEmpty) parts.add(t);
      }
    }

    return parts.map((e) {
      final open = e.lastIndexOf('(');
      final close = e.lastIndexOf(')');
      if (open != -1 && close != -1 && close > open + 1) {
        final name = e.substring(0, open).trim();
        final qty = e.substring(open + 1, close).trim();
        return '$name ×$qty';
      }
      return e;
    }).toList();
  }

  IconData _iconFor(DishCategory cat) {
    switch (cat) {
      case DishCategory.freshlyMade: return Icons.restaurant;
      case DishCategory.buffet: return Icons.table_bar;
      case DishCategory.takeout: return Icons.shopping_bag_outlined;
      case DishCategory.vegGarden: return Icons.grass;
      case DishCategory.foodTruck: return Icons.local_shipping;
      case DishCategory.unknown: return Icons.fastfood;
    }
  }
}

enum DishCategory { freshlyMade, buffet, takeout, vegGarden, foodTruck, unknown }

DishCategory _inferCategory(Dish d) {
  final s = d.sections.map((e) => e.toLowerCase()).toList();
  bool has(String label) => s.contains(label.toLowerCase());
  if (has('Freshly Made') || has('Fresh Dishes')) return DishCategory.freshlyMade;
  if (has('Buffet')) return DishCategory.buffet;
  if (has('Takeout')) return DishCategory.takeout;
  if (has('Vegetable Garden Recipes') || has('Vegetable Garden')) return DishCategory.vegGarden;
  if (has('Food Truck') || has('Food Truck Recipes')) return DishCategory.foodTruck;
  return DishCategory.unknown;
}

