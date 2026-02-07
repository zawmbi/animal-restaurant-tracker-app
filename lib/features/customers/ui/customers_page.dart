import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';

enum CustomerSort {
  nameAZ,
  nameZA,
  ownedFirst,
  unownedFirst,
  bySeason,
}

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
    _tabs = TabController(length: 6, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Regular'),
            Tab(text: 'Special'),
            Tab(text: 'Seasonal'),
            Tab(text: 'Booth Owner'),
            Tab(text: 'Performer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CustomersGrid(), // all
          _CustomersGrid(tag: 'regular'),
          _CustomersGrid(tag: 'special'),
          _CustomersGrid(seasonal: true),
          _CustomersGrid(tag: 'booth_owner'),
          _CustomersGrid(tag: 'performer'),
        ],
      ),
    );
  }
}

class _CustomersGrid extends StatefulWidget {
  final String? tag;
  final bool seasonal;
  const _CustomersGrid({this.tag, this.seasonal = false});

  @override
  State<_CustomersGrid> createState() => _CustomersGridState();
}

class _CustomersGridState extends State<_CustomersGrid> {
  final store = UnlockedStore.instance;

  static const String _bucketCustomers = 'customers';

  CustomerSort _sort = CustomerSort.nameAZ;

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);
  }

  Future<List<Customer>> _load() {
    if (widget.seasonal) return CustomersRepository.instance.seasonal();
    if (widget.tag == null) return CustomersRepository.instance.all();
    return CustomersRepository.instance.withTag(widget.tag!);
  }

  int _unlockedCount(List<Customer> list) {
    var c = 0;
    for (final x in list) {
      if (store.isUnlocked(_bucketCustomers, x.id)) c++;
    }
    return c;
  }

  List<Customer> _applySort(List<Customer> list) {
    final out = [...list];

    switch (_sort) {
      case CustomerSort.nameAZ:
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CustomerSort.nameZA:
        out.sort((a, b) => b.name.compareTo(a.name));
        break;
      case CustomerSort.ownedFirst:
        out.sort((a, b) {
          final aOwned = store.isUnlocked(_bucketCustomers, a.id) ? 0 : 1;
          final bOwned = store.isUnlocked(_bucketCustomers, b.id) ? 0 : 1;
          final cmp = aOwned.compareTo(bOwned);
          return cmp != 0 ? cmp : a.name.compareTo(b.name);
        });
        break;
      case CustomerSort.unownedFirst:
        out.sort((a, b) {
          final aOwned = store.isUnlocked(_bucketCustomers, a.id) ? 1 : 0;
          final bOwned = store.isUnlocked(_bucketCustomers, b.id) ? 1 : 0;
          final cmp = aOwned.compareTo(bOwned);
          return cmp != 0 ? cmp : a.name.compareTo(b.name);
        });
        break;
      case CustomerSort.bySeason:
        out.sort((a, b) {
          final aSeason = a.season ?? '';
          final bSeason = b.season ?? '';
          final cmp = aSeason.compareTo(bSeason);
          return cmp != 0 ? cmp : a.name.compareTo(b.name);
        });
        break;
    }

    return out;
  }

  Future<void> _openDetail(Customer c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: c)),
    );
    if (mounted) setState(() {}); // refresh counts + checkboxes
  }

  Future<void> _toggle(Customer c, bool v) async {
    await store.setUnlocked(_bucketCustomers, c.id, v);
    if (mounted) setState(() {});
  }

  String _sortLabel(CustomerSort sort) {
    switch (sort) {
      case CustomerSort.nameAZ:
        return 'Name (A\u2013Z)';
      case CustomerSort.nameZA:
        return 'Name (Z\u2013A)';
      case CustomerSort.ownedFirst:
        return 'Owned first';
      case CustomerSort.unownedFirst:
        return 'Unowned first';
      case CustomerSort.bySeason:
        return 'By season';
    }
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

        // Keep UI live when any checkbox changes elsewhere
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final sorted = _applySort(customers);
            final unlocked = _unlockedCount(sorted);
            final total = sorted.length;

            return Column(
              children: [
                // ---- Count header + sort button ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Unlocked: $unlocked/$total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      PopupMenuButton<CustomerSort>(
                        initialValue: _sort,
                        onSelected: (v) => setState(() => _sort = v),
                        tooltip: 'Sort',
                        icon: const Icon(Icons.sort),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: CustomerSort.nameAZ,
                            child: Text(_sortLabel(CustomerSort.nameAZ)),
                          ),
                          PopupMenuItem(
                            value: CustomerSort.nameZA,
                            child: Text(_sortLabel(CustomerSort.nameZA)),
                          ),
                          PopupMenuItem(
                            value: CustomerSort.ownedFirst,
                            child: Text(_sortLabel(CustomerSort.ownedFirst)),
                          ),
                          PopupMenuItem(
                            value: CustomerSort.unownedFirst,
                            child: Text(_sortLabel(CustomerSort.unownedFirst)),
                          ),
                          if (widget.seasonal)
                            PopupMenuItem(
                              value: CustomerSort.bySeason,
                              child: Text(_sortLabel(CustomerSort.bySeason)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ---- Grid ----
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1, // square
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final c = sorted[i];
                      final checked =
                          store.isUnlocked(_bucketCustomers, c.id);

                      return _CustomerTile(
                        name: c.name,
                        checked: checked,
                        onTap: () => _openDetail(c),
                        onChanged: (v) => _toggle(c, v),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final String name;
  final bool checked;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  const _CustomerTile({
    required this.name,
    required this.checked,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.brown.shade200.withOpacity(.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Stack(
            children: [
              // Name centered, wraps inside box
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: Center(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),

              // Checkbox corner
              Positioned(
                top: 4,
                right: 4,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Checkbox(
                    value: checked,
                    onChanged: (v) {
                      if (v == null) return;
                      onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
