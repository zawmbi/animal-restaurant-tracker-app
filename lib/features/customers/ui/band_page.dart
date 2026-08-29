// lib/features/customers/ui/band_page.dart

import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../model/customer.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
import 'customer_detail_page.dart';

/// Every performer in one band, each opening that performer's page.
///
/// The performer page used to print the band as plain text, which was a dead
/// end: there was no way to see who else was in the group.
class BandPage extends StatefulWidget {
  const BandPage({super.key, required this.band});

  final String band;

  @override
  State<BandPage> createState() => _BandPageState();
}

class _BandPageState extends State<BandPage> {
  static const String _bucketCustomers = 'customers';

  final store = UnlockedStore.instance;
  late final Future<List<Customer>> _future = _load();

  Future<List<Customer>> _load() async {
    final all = await CustomersRepository.instance.all();
    // Source order, so members appear in the game's order rather than
    // alphabetically.
    return all
        .where((c) => c.performer?.band == widget.band)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.band)),
      body: FutureBuilder<List<Customer>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final members = snap.data ?? const <Customer>[];
          if (members.isEmpty) {
            return const Center(child: Text('No members found for this band.'));
          }

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final owned = members
                  .where((c) => store.isUnlocked(_bucketCustomers, c.id))
                  .length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$owned / ${members.length} unlocked',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      CheckAllButton(
                        bucket: _bucketCustomers,
                        ids: members.map((c) => c.id).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final c in members)
                    Card(
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: c.customerDescription.isEmpty
                            ? null
                            : Text(
                                c.customerDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Checkbox(
                          value: store.isUnlocked(_bucketCustomers, c.id),
                          onChanged: (v) => store.setUnlocked(
                            _bucketCustomers,
                            c.id,
                            v ?? false,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailPage(customer: c),
                            ),
                          );
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
