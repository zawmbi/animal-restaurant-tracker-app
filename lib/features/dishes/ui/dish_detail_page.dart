import 'package:flutter/material.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import '../../shared/data/unlocked_store.dart';

// NEW: to link dishes ↔ customers
import '../../customers/data/customers_repository.dart';
import '../../customers/model/customer.dart';
import '../../customers/ui/customer_detail_page.dart';

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
              child: Text(
                'Failed to load recipe:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final dish = snap.data;
          if (dish == null) {
            return const Center(child: Text('Recipe not found.'));
          }

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) =>
                _FreshDishDetailBody(dish: dish, store: store),
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
              onChanged: (v) =>
                  store.setUnlocked('dish', dish.id, v ?? false),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---------- Description ----------
        if (dish.description.isNotEmpty)
          Text(
            dish.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),

        // ---------- Freshly Made Details ----------
        if (isFreshlyMade)
          Container(
            decoration: BoxDecoration(
              color: Colors
                  .transparent, // ← removes white background from Card
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.brown.shade200.withOpacity(.4),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(context, 'Recipe Name', Text(dish.name)),

                  if (dish.description.isNotEmpty)
                    _infoRow(context, 'Description', Text(dish.description)),

                  if (dish.timeSeconds != null)
                    _infoRow(
                      context,
                      'Time to cook',
                      Text(_formatSeconds(dish.timeSeconds!)),
                    ),

                  if (dish.earningsMax != null)
                    _infoRow(
                      context,
                      'Earnings per dish',
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/cod.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(_formatNumber(dish.earningsMax!)),
                        ],
                      ),
                    ),

                  _infoRow(
                    context,
                    'Star requirement',
                    dish.requirementsStars != null &&
                            dish.requirementsStars! > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/star.png',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 4),
                              Text('${dish.requirementsStars}'),
                            ],
                          )
                        : const Text('—'),
                  ),

                  _infoRow(
                    context,
                    'Cost of the recipe',
                    _buildCodCostValue(dish.price, dish.costText),
                  ),
                ],
              ),
            ),
          ),

        if (!isFreshlyMade)
          const Text('Details for other recipe types coming soon.'),

        const SizedBox(height: 16),

        // ---------- NEW: customer sections ----------
        _buildCustomerSections(context),
      ],
    );
  }

  // ---------- NEW: "Required for" + "Can order" ----------
  Widget _buildCustomerSections(BuildContext context) {
    return FutureBuilder<List<Customer>>(
      future: CustomersRepository.instance.all(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final customers = snap.data!;
        final dishIdLower = dish.id.toLowerCase();
        final dishNameLower = dish.name.toLowerCase();

        final requiredFor = customers.where((c) {
          final requiredFood = c.requiredFoodId?.toLowerCase();
          final recipesReq =
              c.requirements?.recipes.map((r) => r.toLowerCase()).toList() ??
                  const [];

          return requiredFood == dishIdLower ||
              requiredFood == dishNameLower ||
              recipesReq.contains(dishIdLower) ||
              recipesReq.contains(dishNameLower);
        }).toList();

        final canOrder = customers.where((c) {
          final orderedLower =
              c.dishesOrderedIds.map((d) => d.toLowerCase()).toList();
          return orderedLower.contains(dishIdLower) ||
              orderedLower.contains(dishNameLower);
        }).toList();

        if (requiredFor.isEmpty && canOrder.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final children = <Widget>[];

        if (requiredFor.isNotEmpty) {
          children.addAll([
            Text('Required for', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: requiredFor
                  .map(
                    (c) => ActionChip(
                      label: Text(c.name),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailPage(customer: c),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ]);
        }

        if (canOrder.isNotEmpty) {
          children.addAll([
            Text('Customers who can order this dish',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: canOrder
                  .map(
                    (c) => ActionChip(
                      label: Text(c.name),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailPage(customer: c),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ]);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  // ---------- Helper Row ----------
  Widget _infoRow(BuildContext context, String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DefaultTextStyle(
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  // ---------- Cost Row with Icon ----------
  Widget _buildCodCostValue(List<Price>? prices, String? costText) {
    if (prices == null || prices.isEmpty) {
      return Text(costText ?? 'Free');
    }

    final codPrice = prices.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/cod.png',
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 4),
        Text(_formatNumber(codPrice.amount)),
      ],
    );
  }

  // ---------- Formatting ----------
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
}
