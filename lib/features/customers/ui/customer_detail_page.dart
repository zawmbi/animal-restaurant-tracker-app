// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../model/customer.dart';
import '../../shared/data/unlocked_store.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/ui/dish_detail_page.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;
    final checked = store.isUnlocked('customer', customer.id);

    final requiredFood = _stringOrNull(customer.requiredFoodId);
    final ordered = (customer.dishesOrderedIds ?? const <String>[]).where((e) => e.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(customer.name, style: Theme.of(context).textTheme.headlineSmall),
              ),
              Checkbox(
                value: checked,
                onChanged: (v) => store.setUnlocked('customer', customer.id, v ?? false),
              ),
            ],
          ),

          // Lives In / Tags
          if ((customer.livesIn?.isNotEmpty ?? false) || (customer.tags.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                if (customer.livesIn?.isNotEmpty ?? false)
                  Chip(label: Text(customer.livesIn!)),
                ...customer.tags.map((t) => Chip(label: Text(_titleFromTag(t)))),
              ],
            ),
          ],

          // Description
          if ((customer.customerDescription?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Text(customer.customerDescription!),
          ],

          const SizedBox(height: 16),
          // Required Food
          if (requiredFood != null) _dishBlock(
            context: context,
            title: 'Required Dish(s)',
            items: [requiredFood],
          ),

          // Ordered dishes
          if (ordered.isNotEmpty) ...[
            const SizedBox(height: 16),
            _dishBlock(
              context: context,
              title: 'All Possible Orders',
              items: ordered,
            ),
          ],
        ],
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _dishBlock({
    required BuildContext context,
    required String title,
    required List<String> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: items.map((ref) => _DishChip(ref: ref)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFromTag(String tag) => tag
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String? _stringOrNull(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }
}

class _DishChip extends StatelessWidget {
  const _DishChip({required this.ref});
  final String ref; // could be id: "taiyaki" OR name: "Taiyaki"

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(ref),
      onPressed: () async {
        final repo = DishesRepository.instance;
        final dish = await repo.resolve(ref); // <-- works with id OR name
        if (dish == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recipe not found for "$ref"')),
          );
          return;
        }
        // Always navigate by the canonical id:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DishDetailPage(dishId: dish.id)),
        );
      },
    );
  }
}
