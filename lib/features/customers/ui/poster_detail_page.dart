import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../data/posters_repository.dart';
import '../model/customer.dart';
import '../model/poster.dart';
import 'customer_detail_page.dart';

class PosterDetailPage extends StatefulWidget {
  final String posterId;
  const PosterDetailPage({super.key, required this.posterId});

  @override
  State<PosterDetailPage> createState() => _PosterDetailPageState();
}

class _PosterDetailPageState extends State<PosterDetailPage> {
  static const String _bucketPoster = 'poster';
  final store = UnlockedStore.instance;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketPoster);
  }

  Future<void> _openCustomer(BuildContext context, String id) async {
    final Customer? c = await CustomersRepository.instance.byId(id);
    if (!context.mounted || c == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: c)),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final checked = store.isUnlocked(_bucketPoster, widget.posterId);

    return Scaffold(
      appBar: AppBar(title: const Text('Poster')),
      body: FutureBuilder<Poster?>(
        future: PostersRepository.instance.byId(widget.posterId),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final poster = snap.data;
          if (poster == null) {
            return const Center(child: Text('Poster not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      poster.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Checkbox(
                    value: checked,
                    onChanged: (v) => store.setUnlocked(
                      _bucketPoster,
                      widget.posterId,
                      v ?? false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (poster.description.isNotEmpty) Text(poster.description),
              const SizedBox(height: 12),

              Text(
                'Earning increase: +${poster.earningIncreasePercent}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 16),

              if (poster.requiredPerformerIds.isNotEmpty) ...[
                const Text(
                  'Performer(s) on this poster',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: poster.requiredPerformerIds.map((id) {
                    return ActionChip(
                      label: Text(id),
                      onPressed: () => _openCustomer(context, id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (poster.requirements.hasAny) ...[
                const Text(
                  'Requirements',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (poster.requirements.customers.isNotEmpty) ...[
                  const Text('Unlock customers:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: poster.requirements.customers.map((id) {
                      return ActionChip(
                        label: Text(id),
                        onPressed: () => _openCustomer(context, id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                if (poster.requirements.facilities.isNotEmpty) ...[
                  const Text('Unlock items/facilities:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: poster.requirements.facilities
                        .map((id) => Chip(label: Text(id)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                if (poster.requirements.notes.isNotEmpty) ...[
                  const Text('Notes:'),
                  const SizedBox(height: 6),
                  ...poster.requirements.notes.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $n'),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
