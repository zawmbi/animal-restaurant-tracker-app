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
    final store = UnlockedStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: FutureBuilder<Dish?>(
        future: repo.byId(dishId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load recipe:\n${snap.error}',
                  textAlign: TextAlign.center),
            );
          }

          final dish = snap.data;
          if (dish == null) {
            return const Center(child: Text('Recipe not found.'));
          }

          // Rebuild details when unlock state changes so the checkbox updates.
          return AnimatedBuilder(
            animation: store,
            builder: (context, _) => _FreshDishDetailBody(dish: dish, store: store),
          );
        },
      ),
    );
  }
}

class _FreshDishDetailBody extends StatelessWidget {
  const _FreshDishDetailBody({required this.dish, required this.store});
  final Dish dish;
  final UnlockedStore store;

  bool get isFreshlyMade =>
      dish.sections.any((s) =>
          s.toLowerCase().contains('freshly made') ||
          s.toLowerCase().contains('fresh dishes'));

  @override
  Widget build(BuildContext context) {
    final checked = store.isUnlocked('dish', dish.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------- Title Row ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                dish.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (v) => store.setUnlocked('dish', dish.id, v ?? false),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---------- Description ----------
        if (dish.description.isNotEmpty)
          Text(dish.description,
              style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),

        // ---------- Freshly Made Details ----------
        if (isFreshlyMade)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(context, 'Recipe Name', dish.name),
                  if (dish.description.isNotEmpty)
                    _infoRow(context, 'Description', dish.description),
                  if (dish.timeSeconds != null)
                    _infoRow(context, 'Time to cook',
                        _formatSeconds(dish.timeSeconds!)),
                  if (dish.earningsMax != null)
                    _infoRow(context, 'Earnings per dish (Cod)',
                        '🐟 ${_formatNumber(dish.earningsMax!)}'),
                  _infoRow(
                      context,
                      'Star requirement',
                      dish.requirementsStars != null &&
                              dish.requirementsStars! > 0
                          ? '${dish.requirementsStars}★'
                          : '—'),
                  _infoRow(context, 'Cost of the recipe (Cod)',
                      _firstCodCost(dish.price) ?? dish.costText ?? 'Free'),
                ],
              ),
            ),
          ),

        // ---------- Placeholder for other sections ----------
        if (!isFreshlyMade)
          const Text('Details for other recipe types coming soon.'),
      ],
    );
  }

  // ---------- Helper UI ----------
  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  // ---------- Formatting helpers ----------
  static String _formatSeconds(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final sec = s % 60;
    return sec == 0 ? '${m}m' : '${m}m ${sec}s';
  }

  static String _formatNumber(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String? _firstCodCost(List<Price>? prices) {
    if (prices == null || prices.isEmpty) return null;
    final codPrice =
        prices.firstWhere((p) => p.currency.toLowerCase() == 'cod',
            orElse: () => prices.first);
    return '🐟 ${_formatNumber(codPrice.amount)}';
  }
}
