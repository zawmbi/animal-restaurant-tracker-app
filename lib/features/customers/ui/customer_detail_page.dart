import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/ui/dish_detail_page.dart';
import '../model/customer.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final unlocked = store.isUnlocked('customer', customer.id);
        return Scaffold(
          appBar: AppBar(title: Text(customer.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Unlocked'),
                value: unlocked,
                onChanged: (v) => store.setUnlocked('customer', customer.id, v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              _info('Lives in', customer.livesIn),
              _info('Appearance weight', customer.appearanceWeight.toString()),
              const SizedBox(height: 12),
              if (customer.requiredFoodId != null) ...[
                const Text('Required Food', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _dishChip(context, customer.requiredFoodId!),
                const SizedBox(height: 12),
              ],
              if (customer.dishesOrderedIds.isNotEmpty) ...[
                const Text('Dishes Ordered', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customer.dishesOrderedIds
                      .map((id) => _dishChip(context, id))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (customer.mementos.isNotEmpty) ...[
                const Text('Mementos', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...customer.mementos.map((m) => ListTile(
                      leading: CircleAvatar(child: Text('+${m.stars}')),
                      title: Text(m.name),
                      subtitle: Text(m.requirement),
                    )),
              ],

              const SizedBox(height: 24),
              Wrap(
                spacing: 6,
                children: customer.tags
                    .map((t) => Chip(label: Text(t)))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _info(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _dishChip(BuildContext context, String dishId) {
    final store = UnlockedStore.instance;
    return FutureBuilder(
      future: DishesRepository.instance.byId(dishId),
      builder: (context, snap) {
        final label = snap.data?.name ?? dishId; // fallback to id until loaded 
        final checked = store.isUnlocked('dish', dishId);
        return EntityChip(
          label: label,
          checked: checked,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(

                builder: (_) => DishDetailPage(dishId: dishId),
              ),
            );
          },
        );
      },
    );
  }
}