import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Regular'),
            Tab(text: 'Booth Owner'),
            Tab(text: 'Performer'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CustomersGrid(),
          _CustomersGrid(tag: 'regular'),
          _CustomersGrid(tag: 'booth_owner'),
          _CustomersGrid(tag: 'performer'),
          _CustomersGrid(tag: 'special'),
        ],
      ),
    );
  }
}

class _CustomersGrid extends StatefulWidget {
  final String? tag;
  const _CustomersGrid({this.tag});

  @override
  State<_CustomersGrid> createState() => _CustomersGridState();
}

class _CustomersGridState extends State<_CustomersGrid> {
  static const String _bucketCustomers = 'customers';
  final store = UnlockedStore.instance;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);
  }

  Future<List<Customer>> _load() {
    return widget.tag == null
        ? CustomersRepository.instance.all()
        : CustomersRepository.instance.withTag(widget.tag!);
  }

  bool _isUnlocked(Customer c) => store.isUnlocked(_bucketCustomers, c.id);

  int _unlockedCount(List<Customer> list) {
    var n = 0;
    for (final c in list) {
      if (_isUnlocked(c)) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Customer>>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = snap.data!;
        final total = customers.length;
        final unlocked = _unlockedCount(customers);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '$unlocked/$total unlocked',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: customers.length,
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final isUnlocked = _isUnlocked(c);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailPage(customer: c),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: isUnlocked ? 1.0 : 0.55,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            c.name,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
