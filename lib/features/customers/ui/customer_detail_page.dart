import 'package:flutter/material.dart';

import '../model/customer.dart';
import '../../dishes/ui/dish_detail_page.dart';
import '../../facilities/ui/facility_detail_page.dart';
import '../../letters/ui/letter_detail_page.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../mementos/data/mementos_index.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../shared/data/unlocked_store.dart';
import '../../mementos/ui/mementos_detail_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final store = UnlockedStore.instance;

  // Buckets that match YOUR app pages
  static const String _bucketDish = 'dish';
  static const String _bucketLetter = 'letter';
  static const String _bucketFacility = 'facility'; // change if yours differs
  static const String _bucketMementoCollected = 'memento_collected';

  Customer get customer => widget.customer;

  Color _ownedFill(BuildContext context) => Colors.green.withOpacity(0.18);

  @override
  Widget build(BuildContext context) {
    final r = customer.requirements;
    final ownedFill = _ownedFill(context);

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

            // Recipes: stored as ids, bucket 'dish'
            _simpleLinks(
              context: context,
              title: 'Required Recipes',
              ids: r.recipes,
              isOwned: (id) => store.isUnlocked(_bucketDish, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DishDetailPage(dishId: id.toString()),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            // Facilities: stored as ids, bucket assumed 'facility'
            _simpleLinks(
              context: context,
              title: 'Required Facilities',
              ids: r.facilities,
              isOwned: (id) => store.isUnlocked(_bucketFacility, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FacilityDetailPage(facilityId: id.toString()),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),

            // Letters: ids -> load Letter -> open LetterDetailPage(letter: Letter)
            _simpleLinks(
              context: context,
              title: 'Required Letters',
              ids: r.letters,
              isOwned: (id) => store.isUnlocked(_bucketLetter, id.toString()),
              fillIfOwned: ownedFill,
              onTap: (id) async {
                final Letter? letter =
                    await LettersRepository.instance.byId(id.toString());
                if (!mounted || letter == null) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LetterDetailPage(letter: letter),
                  ),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),
          ],

          // Mementos: customer.mementos gives you objects with .id/.name
          // BUT your collected key in MementosPage is e.key under bucket 'memento_collected'
          // So we resolve the index entry first and use entry.key for ownership.
          if (customer.mementos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Mementos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customer.mementos.map((m) {
                return FutureBuilder(
                  future: MementosIndex.instance.byId(m.id),
                  builder: (context, snap) {
                    final entry = snap.data;

                    final collected = (entry != null)
                        ? store.isUnlocked('memento_collected', entry.key)
                        : false;

                    return EntityChip(
                      label: m.name,
                      fillColor: collected ? Colors.green.withOpacity(0.18) : null,
                      onTap: () async {
                        final real = entry ?? await MementosIndex.instance.byId(m.id);
                        if (real == null || !context.mounted) return;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MementoDetailPage(memento: real),
                          ),
                        );

                        // IMPORTANT: requires CustomerDetailPage to be StatefulWidget
                        if (mounted) setState(() {});
                      },
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

  Widget _simpleLinks({
    required BuildContext context,
    required String title,
    required List ids,
    required bool Function(dynamic id) isOwned,
    required Color fillIfOwned,
    required Future<void> Function(dynamic id) onTap,
  }) {
    if (ids.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ids.map((id) {
            final owned = isOwned(id);
            return EntityChip(
              label: id.toString(),
              fillColor: owned ? fillIfOwned : null,
              onTap: () => onTap(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
