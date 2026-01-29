import 'package:flutter/material.dart';
import '../data/dishes_repository.dart';
import '../model/dish.dart';
import '../../shared/data/unlocked_store.dart';

// to link dishes ↔ customers
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
            builder: (context, _) => _DishDetailBody(dish: dish, store: store),
          );
        },
      ),
    );
  }
}

class _DishDetailBody extends StatelessWidget {
  const _DishDetailBody({required this.dish, required this.store});

  final Dish dish;
  final UnlockedStore store;

  bool get isFreshlyMade =>
      dish.sections.any((s) =>
          s.toLowerCase().contains('freshly made') ||
          s.toLowerCase().contains('fresh dishes'));

  bool get isBuffet =>
      dish.sections.any((s) => s.toLowerCase().contains('buffet'));

  bool get isTakeout =>
      dish.sections.any((s) => s.toLowerCase().contains('takeout'));

  bool get isFoodTruck =>
      dish.sections.any((s) => s.toLowerCase().contains('food truck'));

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
          Text(
            dish.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),

        if (isFreshlyMade) _freshlyMadeCard(context),
        if (isBuffet) _buffetCard(context),
        if (isTakeout) _takeoutCard(context),
        if (isFoodTruck) _foodTruckCard(context),

        if (!isFreshlyMade && !isBuffet && !isTakeout && !isFoodTruck)
          const Text('Details for this recipe type are not implemented yet.'),

        const SizedBox(height: 16),

        // ---------- customer sections ----------
        _buildCustomerSections(context),
      ],
    );
  }

  // ------------------ Cards ------------------

  Widget _cardShell(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.brown.shade200.withOpacity(.4),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _freshlyMadeCard(BuildContext context) {
    return _cardShell(
      context,
      [
        _infoRow(context, 'Recipe Name', Text(dish.name)),
        if (dish.description.isNotEmpty)
          _infoRow(context, 'Description', Text(dish.description)),
        if (dish.timeSeconds != null)
          _infoRow(context, 'Time to cook', Text(_formatSeconds(dish.timeSeconds!))),
        if (dish.earningsMax != null)
          _infoRow(
            context,
            'Earnings per dish',
            _moneyRow(currency: 'cod', amount: dish.earningsMax!),
          ),
        _infoRow(
          context,
          'Star requirement',
          (dish.requiredStars != null && dish.requiredStars! > 0)
              ? _iconNumberRow(iconAsset: 'assets/images/star.png', value: dish.requiredStars!.toString())
              : const Text('—'),
        ),
        _infoRow(
          context,
          'Cost of the recipe',
          _buildPriceValue(dish.price, dish.costText),
        ),
      ],
    );
  }

  Widget _buffetCard(BuildContext context) {
    return _cardShell(
      context,
      [
        _infoRow(context, 'Recipe Name', Text(dish.name)),
        if (dish.description.isNotEmpty)
          _infoRow(context, 'Description', Text(dish.description)),
        if (dish.earningsPerHour != null && dish.earningsPerHour!.isNotEmpty)
          _infoRow(
            context,
            'Earnings per hour',
            _moneyRow(currency: 'cod', amount: dish.earningsPerHourInt ?? 0, suffix: '/h'),
          ),
        _infoRow(
          context,
          'Star requirement',
          (dish.requiredStars != null && dish.requiredStars! > 0)
              ? _iconNumberRow(iconAsset: 'assets/images/star.png', value: dish.requiredStars!.toString())
              : const Text('—'),
        ),
        _infoRow(
          context,
          'Cost',
          _buildPriceValue(dish.price, dish.costText),
        ),
      ],
    );
  }

  Widget _takeoutCard(BuildContext context) {
    final children = <Widget>[
      _infoRow(context, 'Recipe Name', Text(dish.name)),
      if (dish.description.isNotEmpty)
        _infoRow(context, 'Description', Text(dish.description)),
      if (dish.earningsRange != null && dish.earningsRange!.isNotEmpty)
        _infoRow(
          context,
          'Earnings range',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/bell.png', width: 18, height: 18),
              const SizedBox(width: 4),
              Text(dish.earningsRange!),
            ],
          ),
        ),
      if (dish.requirementsLikes != null && dish.requirementsLikes! > 0)
        _infoRow(
          context,
          'Base likes requirement',
          _iconNumberRow(iconAsset: 'assets/images/like.png', value: dish.requirementsLikes!.toString()),
        ),
      if (dish.requiredStars != null && dish.requiredStars! > 0)
        _infoRow(
          context,
          'Base star requirement',
          _iconNumberRow(iconAsset: 'assets/images/star.png', value: dish.requiredStars!.toString()),
        ),
    ];

    if (dish.tiers != null && dish.tiers!.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Text('Tiers', style: Theme.of(context).textTheme.titleMedium));
      children.add(const SizedBox(height: 6));
      children.addAll(dish.tiers!.map((t) => _tierCard(context, t)));
    }

    return _cardShell(context, children);
  }

  Widget _tierCard(BuildContext context, DishTier t) {
    final tierLabel = (t.tier ?? '').trim().isEmpty ? '—' : t.tier!.trim();

    final reqStars = t.requiredStars ?? 0;
    final reqLikes = t.requirementsLikes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown.shade200.withOpacity(.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tier $tierLabel', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset('assets/images/star.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(reqStars > 0 ? _formatNumber(reqStars) : '—'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Image.asset('assets/images/like.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(reqLikes > 0 ? _formatNumber(reqLikes) : '—'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Cost: '),
              _buildPriceValue(t.price, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _foodTruckCard(BuildContext context) {
    final children = <Widget>[
      _infoRow(context, 'Recipe Name', Text(dish.name)),
      if (dish.description.isNotEmpty)
        _infoRow(context, 'Description', Text(dish.description)),
      if (dish.refinedRating != null)
        _infoRow(
          context,
          'Refined rating',
          _iconNumberRow(iconAsset: 'assets/images/star.png', value: '+${dish.refinedRating}'),
        ),
      if (dish.prepTimeSeconds != null)
        _infoRow(context, 'Prep time', Text(_formatSeconds(dish.prepTimeSeconds!))),
      if (dish.perfectDishes != null)
        _infoRow(context, 'Perfect dishes', Text('${dish.perfectDishes}')),
      if (dish.flavor != null && dish.flavor!.trim().isNotEmpty)
        _infoRow(context, 'Flavor', Text(dish.flavor!)),
    ];

    if (dish.ingredientsList != null && dish.ingredientsList!.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Text('Ingredients', style: Theme.of(context).textTheme.titleMedium));
      children.add(const SizedBox(height: 6));
      children.add(_ingredientWrap(context, dish.ingredientsList!));
    }

    return _cardShell(context, children);
  }

  Widget _ingredientWrap(BuildContext context, List<DishIngredient> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((ing) {
        final amt = ing.amount;
        final amtText = (amt != null && amt > 0) ? ' x$amt' : '';
        return Chip(label: Text('${ing.item}$amtText'));
      }).toList(),
    );
  }

  // ------------------ Customers ------------------

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

  // ------------------ Helpers ------------------

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

  Widget _iconNumberRow({required String iconAsset, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconAsset, width: 18, height: 18),
        const SizedBox(width: 4),
        Text(value),
      ],
    );
  }

  Widget _moneyRow({required String currency, required int amount, String? suffix}) {
    final icon = _currencyIcon(currency);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 20, height: 20),
        const SizedBox(width: 4),
        Text('${_formatNumber(amount)}${suffix ?? ''}'),
      ],
    );
  }

  Widget _buildPriceValue(List<Price>? prices, String? costText) {
    if (prices == null || prices.isEmpty) {
      return Text(costText ?? 'Free');
    }

    // Many of your recipes have a single currency, but we support multiples cleanly.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < prices.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Image.asset(_currencyIcon(prices[i].currency), width: 20, height: 20),
          const SizedBox(width: 4),
          Text(_formatNumber(prices[i].amount)),
        ],
      ],
    );
  }

  static String _currencyIcon(String currency) {
    final c = currency.trim().toLowerCase();
    switch (c) {
      case 'cod':
        return 'assets/images/cod.png';
      case 'plates':
        return 'assets/images/plate.png';
      case 'bells':
        return 'assets/images/bell.png';
      default:
        // Fallback to cod icon so UI never breaks, but still uses an asset.
        return 'assets/images/cod.png';
    }
  }

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
