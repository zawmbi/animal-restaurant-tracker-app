import 'package:flutter/material.dart';
import '../model/customer.dart';
import '../../dishes/ui/dish_detail_page.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../letters/ui/letter_detail_page.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../mementos/data/mementos_index.dart';


class CustomerDetailPage extends StatelessWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final r = customer.requirements;

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(customer.customerDescription),

          const SizedBox(height: 16),
          _section('Lives In', Text(customer.livesIn)),
          _section(
            'Appearance Weight',
            Text(customer.appearanceWeight.toString()),
          ),

          if (r != null && r.hasAny) ...[
            const SizedBox(height: 24),
            const Text(
              'Requirements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            if (r.rating != null)
              _currencyRow(
                'assets/images/star.png',
                'Rating',
                r.rating!,
              ),

            _links(
              context,
              'Required Recipes',
              r.recipes,
              (id) => DishDetailPage(dishId: id),
            ),

            _links(
              context,
              'Required Facilities',
              r.facilities,
              (id) => FacilityDetailPage(facilityId: id),
            ),

            _links(
              context,
              'Required Letters',
              r.letters,
              (id) => LetterDetailPage(letter: id),
            ),
          ],
if (customer.mementos.isNotEmpty) ...[
  const SizedBox(height: 24),
  const Text(
    'Mementos',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  Wrap(
    spacing: 8,
    children: customer.mementos.map((m) {
      return EntityChip(
        label: m.name,
        onTap: () async {
          // 🔑 resolve the REAL memento entry
          final entry =
              await MementosIndex.instance.byId(m.id);

          if (entry == null || !context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(entry.name ?? 'Memento')),
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(entry.description ?? ''),
                ),
              ),
            ),
          );
        },
      );
    }).toList(),
  ),
],

        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _currencyRow(String image, String label, int value) {
    return Row(
      children: [
        Image.asset(image, width: 20),
        const SizedBox(width: 8),
        Text('$label: $value'),
      ],
    );
  }

  Widget _links(
    BuildContext context,
    String title,
    List ids,
    Widget Function(dynamic id) pageBuilder,
  ) {
    if (ids.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: ids
              .map(
                (id) => EntityChip(
                  label: id.toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => pageBuilder(id)),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
