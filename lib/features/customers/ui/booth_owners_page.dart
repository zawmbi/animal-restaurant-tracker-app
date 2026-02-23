import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';

enum BoothSort {
  nameAZ,
  nameZA,
  stayShortest,
  stayLongest,
  incomeBestExpected, // uses boothOwner rules if present
}

class BoothOwnersPage extends StatefulWidget {
  const BoothOwnersPage({super.key});

  @override
  State<BoothOwnersPage> createState() => _BoothOwnersPageState();
}

class _BoothOwnersPageState extends State<BoothOwnersPage> {
  static const String _bucketCustomers = 'customers';
  final store = UnlockedStore.instance;

  BoothSort _sort = BoothSort.nameAZ;
  String? _fishFilterId;

  static const _regularFish = [
    ('clownfish', 'Clownfish'),
    ('crab', 'Crab'),
    ('flounder', 'Flounder'),
    ('jellyfish', 'Jellyfish'),
    ('pink_shell', 'Pink Shell'),
    ('red_puffer', 'Red Puffer'),
    ('shark', 'Shark'),
    ('squid', 'Squid'),
    ('starfish', 'Starfish'),
    ('tree_branch', 'Tree Branch'),
  ];

  static const _specialtyFish = [
    ('sea_urchin', 'Sea Urchin'),
    ('cuttlefish', 'Cuttlefish'),
    ('seahorse', 'Seahorse'),
    ('hermit_crab', 'Hermit Crab'),
    ('goldfish', 'Goldfish'),
  ];

  static const _rareFish = [
    ('butterflyfish', 'Butterflyfish'),
    ('ray', 'Ray'),
  ];

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);
  }

  bool _isUnlocked(Customer c) => store.isUnlocked(_bucketCustomers, c.id);

  int _unlockedCount(List<Customer> list) {
    var n = 0;
    for (final c in list) {
      if (_isUnlocked(c)) n++;
    }
    return n;
  }

  double _expectedIncomeEvery5Min(Customer c) {
    // If you don’t have boothOwner data yet, this safely returns 0.
    // Once you add boothOwner.incomeEvery5Min, replace this logic.
    final b = c.boothOwner; // requires you to add this field in model
    if (b == null) return 0;

    var expected = 0.0;
    for (final rule in b.incomeEvery5Min) {
      expected += (rule.chance) * (rule.amount);
    }
    return expected;
  }

  int _stayMin(Customer c) => c.boothOwner?.stayDurationMinutes?.min ?? 0;
  int _stayMax(Customer c) => c.boothOwner?.stayDurationMinutes?.max ?? 0;

  List<Customer> _applyFilters(List<Customer> list) {
    var out = list;

    if (_fishFilterId != null) {
      out = out.where((c) {
        final fish = c.boothOwner?.requiredFishIds ?? const <String>[];
        return fish.contains(_fishFilterId);
      }).toList();
    }

    return out;
  }

  List<Customer> _applySort(List<Customer> list) {
    final out = [...list];

    switch (_sort) {
      case BoothSort.nameAZ:
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case BoothSort.nameZA:
        out.sort((a, b) => b.name.compareTo(a.name));
        break;
      case BoothSort.stayShortest:
        out.sort((a, b) => _stayMin(a).compareTo(_stayMin(b)));
        break;
      case BoothSort.stayLongest:
        out.sort((a, b) => _stayMax(b).compareTo(_stayMax(a)));
        break;
      case BoothSort.incomeBestExpected:
        out.sort((a, b) =>
            _expectedIncomeEvery5Min(b).compareTo(_expectedIncomeEvery5Min(a)));
        break;
    }

    return out;
  }

  Widget _fishChip(String id, String label) {
    final selected = _fishFilterId == id;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _fishFilterId = selected ? null : id;
      }),
    );
  }

  Widget _buildFishFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (id, label) in _regularFish) _fishChip(id, label),
            ],
          ),
          const SizedBox(height: 4),
          Text('Specialty', style: Theme.of(context).textTheme.labelSmall),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (id, label) in _specialtyFish) _fishChip(id, label),
            ],
          ),
          const SizedBox(height: 4),
          Text('Rare', style: Theme.of(context).textTheme.labelSmall),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (id, label) in _rareFish) _fishChip(id, label),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth Owners'),
        actions: [
          PopupMenuButton<BoothSort>(
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: BoothSort.nameAZ,
                child: Text('Name (A–Z)'),
              ),
              PopupMenuItem(
                value: BoothSort.nameZA,
                child: Text('Name (Z–A)'),
              ),
              PopupMenuItem(
                value: BoothSort.stayShortest,
                child: Text('Shortest stay'),
              ),
              PopupMenuItem(
                value: BoothSort.stayLongest,
                child: Text('Longest stay'),
              ),
              PopupMenuItem(
                value: BoothSort.incomeBestExpected,
                child: Text('Best expected income'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Customer>>(
        future: CustomersRepository.instance.withTag('booth_owner'),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data!;
          final filtered = _applyFilters(all);
          final sorted = _applySort(filtered);

          final unlocked = _unlockedCount(sorted);
          final total = sorted.length;

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

              _buildFishFilters(context),

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
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final c = sorted[i];
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
      ),
    );
  }
}
