// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../model/customer.dart';
import '../model/memento.dart';

import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../dishes/ui/dish_detail_page.dart';

import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../facilities/ui/facility_detail_page.dart';

import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../letters/ui/letters_page.dart';

import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TAGS
            if (customer.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: customer.tags
                    .map(
                      (e) => Chip(
                        label: Text(e),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // INFO (NEW: numeric appearance rate)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Lives In', value: customer.livesIn),
                    const SizedBox(height: 6),
                    _InfoRow(
                      label: 'Appearance Rate',
                      value: customer.appearanceWeight.toString(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '(Lower = rarer, higher = more common)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DESCRIPTION
            if (customer.customerDescription.isNotEmpty) ...[
              Text(
                customer.customerDescription,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

          // FAVORITE DISHES (boxed like the others)
          if (customer.dishesOrderedIds.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Favorite Dishes', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: customer.dishesOrderedIds
                            .map(
                              (d) => ActionChip(
                                label: Text(d),
                                onPressed: () => _openEntityById(context, d),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

            // REQUIREMENTS card (clickable chips)
            _RequirementsSection(customer: customer),
            const SizedBox(height: 16),

            // MEMENTOS (each opens specific MementoDetailPage)
            if (customer.mementos.isNotEmpty) ...[
              Text(
                'Mementos',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...customer.mementos.map(
                (m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: ActionChip(
                      label: Text(m.name),
                      onPressed: () => _openMemento(context, m),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(m.description),
                          ),
                        if (m.requirement.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Requirement: ${m.requirement}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _RequirementsSection extends StatelessWidget {
  final Customer customer;

  const _RequirementsSection({required this.customer});

  @override
  Widget build(BuildContext context) {
    final req = customer.requirements;
    if (req == null || !req.hasAny) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    List<Widget> rows = [];

    Widget buildRow(String label, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: items
                    .map(
                      (e) => ActionChip(
                        label: Text(e),
                        onPressed: () => _openEntityById(context, e),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    rows.add(buildRow('Letters', req.letters));
    rows.add(buildRow('Facilities', req.facilities));
    rows.add(buildRow('Recipes', req.recipes));
    rows.add(buildRow('Customers', req.customers));
    rows.add(buildRow('Flowers', req.flowers));

    rows = rows.where((w) => w is! SizedBox).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requirements', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

// ===================================================================
//  HELPERS – data lookup + navigation
// ===================================================================

Future<void> _openEntityById(BuildContext context, String id) async {
  // Try customers
  final customers = await CustomersRepository.instance.all();
  Customer? customer;
  for (final c in customers) {
    if (c.id == id) {
      customer = c;
      break;
    }
  }
  if (customer != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailPage(customer: customer!),
      ),
    );
    return;
  }

  // Try dishes
  final dishes = await DishesRepository.instance.all();
  Dish? dish;
  for (final d in dishes) {
    if (d.id == id) {
      dish = d;
      break;
    }
  }
  if (dish != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DishDetailPage(dishId: dish!.id),
      ),
    );
    return;
  }

  // Try facilities
  final facilities = await FacilitiesRepository.instance.all();
  Facility? facility;
  for (final f in facilities) {
    if (f.id == id) {
      facility = f;
      break;
    }
  }
  if (facility != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacilityDetailPage(facilityId: facility!.id),
      ),
    );
    return;
  }

  // Try letters (no single-letter page yet, so open LettersPage)
  final letters = await LettersRepository.instance.all();
  Letter? letter;
  for (final l in letters) {
    if (l.id == id) {
      letter = l;
      break;
    }
  }

  if (letter != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LettersPage(),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No entity found for "$id".')),
  );
}

Future<void> _openMemento(BuildContext context, Memento memento) async {
  final all = await MementosIndex.instance.all();
  MementoEntry? entry;
  for (final e in all) {
    if (e.id == memento.id) {
      entry = e;
      break;
    }
  }

  if (entry == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Memento not found: ${memento.id}')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MementoDetailPage(memento: entry!),
    ),
  );
}
