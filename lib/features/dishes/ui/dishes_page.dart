
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
        final info = kSampleDishInfos[dish.name]; // sample structured data
        final cat = _inferCategory(dish);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header + checkmark
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

            if ((dish.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(dish.description!),
            ],

            const SizedBox(height: 16),
            if (cat != DishCategory.unknown || info != null)
              _categoryCard(context, cat, info),

            if (info == null)
              _placeholderCard(context),
          ],
        );
      },
    );
  }

  // Fallback card shown when we don't yet have structured fields in JSON.
  Widget _placeholderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No structured stats yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Add per-recipe fields to your data and wire them here. For now, examples below show how info will render for items we have sample data for.'),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(BuildContext context, DishCategory cat, DishInfo? info) {
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
            if (info != null) ...[
              if (info.time != null) _kv('Time', info.time!),
              if (info.earningsMax != null) _kv('Earnings (Max)', info.earningsMax!),
              if (info.earningsPerHour != null) _kv('Earnings', info.earningsPerHour!),
              if (info.requirement != null) _kv('Requirement', info.requirement!),
              if (info.cost != null) _kv('Cost', info.cost!),

              if (info.takeoutTiers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tier Requirements', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final t in info.takeoutTiers)
                  _tierCard(t),
              ],

              if (info.ingredients.isNotEmpty || info.refinedRating != null || info.perfectDishes != null || info.prepTime != null || info.flavor != null) ...[
                const Divider(height: 24),
                if (info.refinedRating != null) _kv('Refined Rating', info.refinedRating!.toString()),
                if (info.perfectDishes != null) _kv('Perfect Dishes', info.perfectDishes!.toString()),
                if (info.prepTime != null) _kv('Prep Time', info.prepTime!),
                if (info.flavor != null) _kv('Flavor', info.flavor!),
                if (info.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: info.ingredients.map((e) => Chip(label: Text(e))).toList(),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
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

  Widget _tierCard(TakeoutTier t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tier ${t.tier}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (t.stars != null) _pill('★ ${_fmtInt(t.stars!)}'),
              if (t.likes != null) _pill('❤ ${_fmtInt(t.likes!)}'),
              if (t.cod != null) _pill('🪙 ${_fmtInt(t.cod!)} cod'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }

  static String _fmtInt(int v) {
    // simple thousands formatting
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  IconData _iconFor(DishCategory cat) {
    switch (cat) {
      case DishCategory.freshlyMade: return Icons.restaurant;
      case DishCategory.buffet: return Icons.conveyor_belt; // available on newer material; fallback below
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

// ---------- Sample structured data to demonstrate rendering ----------
// You can replace this with real fields from your JSON model when ready.

class DishInfo {
  final String? time; // e.g. "2s"
  final String? earningsMax; // e.g. "3,300"
  final String? earningsPerHour; // e.g. "+3,000/h"
  final String? requirement; // generic text, e.g. "15★"
  final String? cost; // generic text, e.g. "900 cod" / "200 plates"

  final List<TakeoutTier> takeoutTiers; // for takeout recipes

  // Food-truck extras
  final int? refinedRating;
  final List<String> ingredients;
  final int? perfectDishes;
  final String? prepTime; // e.g. "26s"
  final String? flavor; // e.g. "Sour"

  const DishInfo({
    this.time,
    this.earningsMax,
    this.earningsPerHour,
    this.requirement,
    this.cost,
    this.takeoutTiers = const [],
    this.refinedRating,
    this.ingredients = const [],
    this.perfectDishes,
    this.prepTime,
    this.flavor,
  });
}

class TakeoutTier {
  final String tier; // C, B, A, S
  final int? stars; // requirement in stars
  final int? likes; // requirement in likes
  final int? cod;   // requirement in cod
  const TakeoutTier({required this.tier, this.stars, this.likes, this.cod});
}

final Map<String, DishInfo> kSampleDishInfos = {
  // ---------------- Freshly Made ----------------
  'Taiyaki': DishInfo(time: '2s', earningsMax: '3,300', cost: 'Free'),
  'Seaweed Rice Ball': DishInfo(time: '3s', earningsMax: '3,400', cost: 'Free'),
  'Purple Sweet Potato Bun': DishInfo(time: '4s', earningsMax: '3,500', requirement: '400★'),
  'Americano': DishInfo(time: '6s', earningsMax: '3,800', requirement: '15★', cost: '900 cod'),
  'Steamed Clams': DishInfo(time: '8s', earningsMax: '3,900', requirement: '25★', cost: '1,000 cod'),
  'Adzuki Bean Dumpling': DishInfo(time: '10s', earningsMax: '4,000', requirement: '40★', cost: '1,100 cod'),
  'Bagel': DishInfo(time: '12s', earningsMax: '800', requirement: '60★', cost: '2,500 cod'),

  // ---------------- Buffet (earnings per hour / cost in plates) ----------------
  'Strawberry Daifuku': DishInfo(earningsPerHour: '+3,000/h', cost: 'Free'),
  'Soymilk': DishInfo(earningsPerHour: '+3,100/h', requirement: '—', cost: '50 plates'),
  'Sushi Roll': DishInfo(earningsPerHour: '+3,200/h', requirement: '—', cost: '100 plates'),
  'Sea Urchin Sushi': DishInfo(earningsPerHour: '+3,300/h', requirement: '2,000★', cost: '200 plates'),
  'Conveyor Sushi Roll': DishInfo(earningsPerHour: '+3,400/h', requirement: '2,200★', cost: '300 plates'),
  'Eel Sushi': DishInfo(earningsPerHour: '+3,500/h', requirement: '2,400★', cost: '400 plates'),

  // ---------------- Takeout (tiered requirements) ----------------
  'Teddy Biscuit': DishInfo(
    earningsMax: '+14~56',
    takeoutTiers: const [
      TakeoutTier(tier: 'C', stars: 3500, cod: 1000),
      TakeoutTier(tier: 'B', likes: 100, cod: 10000),
      TakeoutTier(tier: 'A', stars: 20000, cod: 30000),
      TakeoutTier(tier: 'S', likes: 1000, cod: 1000000),
    ],
  ),
  'Fresh Milk': DishInfo(
    earningsMax: '+15~60',
    takeoutTiers: const [
      TakeoutTier(tier: 'C', stars: 3800, cod: 20000),
      TakeoutTier(tier: 'B', likes: 100, cod: 120000),
      TakeoutTier(tier: 'A', stars: 520, cod: 350000),
      TakeoutTier(tier: 'S', likes: 52000, cod: 1100000),
    ],
  ),
  'Strawberry Cone': DishInfo(
    earningsMax: '+17~64',
    takeoutTiers: const [
      TakeoutTier(tier: 'C', stars: 4100, cod: 30000),
      TakeoutTier(tier: 'B', likes: 11500, cod: 140000),
      TakeoutTier(tier: 'A', stars: 22000, cod: 400000),
      TakeoutTier(tier: 'S', likes: 1200, cod: 1200000),
    ],
  ),

  // ---------------- Food Truck Recipes ----------------
  'Tomatoes in Mashed Potatoes': DishInfo(
    refinedRating: 350,
    ingredients: const ['Potato ×6', 'Tomato ×4'],
    perfectDishes: 35,
    prepTime: '26s',
    flavor: 'Sour',
  ),
  'Tofu Pudding in Sweet Rice Wine': DishInfo(
    refinedRating: 250,
    ingredients: const ['Soybean ×4', 'Rice ×8'],
    perfectDishes: 15,
    prepTime: '24s',
    flavor: 'Sweet',
  ),
  'Mushroom Fried Rice': DishInfo(
    refinedRating: 400,
    ingredients: const ['Rice ×8', 'Mushroom ×5', 'Corn ×3'],
    perfectDishes: 35,
    prepTime: '42s',
    flavor: 'Salty',
  ),
  'Kitty Crepe': DishInfo(
    refinedRating: 150,
    ingredients: const ['Wheat ×4', 'Rice ×3'],
    perfectDishes: 10,
    prepTime: '24s',
    flavor: 'Sweet',
  ),
};

