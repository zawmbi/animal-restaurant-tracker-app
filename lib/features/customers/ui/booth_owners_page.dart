import 'package:flutter/material.dart';

import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/utils/display_names.dart';

enum BoothSort {
  /// Source order, i.e. the wiki's order, which is the game's order.
  wikiOrder,
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

  BoothSort _sort = BoothSort.wikiOrder;
  String _query = '';
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

  static const _rareFish = [('butterflyfish', 'Butterflyfish'), ('ray', 'Ray')];

  @override
  void initState() {
    super.initState();
    store.registerType(_bucketCustomers);

    // Warm the fish name map so searching by fish name works on first
    // keystroke; nameFor falls back to prettifying the id either way.
    FishNames.instance
        .load()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) => <String, String>{});
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
    if (_query.trim().isNotEmpty) {
      // Searchable by fish name too, since that is how a player thinks
      // about which booth owner they are hunting for.
      list = list.where((c) {
        final fishNames = (c.boothOwner?.requiredFishIds ?? const <String>[])
            .map(FishNames.instance.nameFor)
            .join(' ');
        return matchesQuery(
          _query,
          '${c.name} ${c.id} ${c.customerDescription} $fishNames',
        );
      }).toList();
    }
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

    // List.sort is unstable, so ties fall back to source position.
    final order = <String, int>{
      for (var i = 0; i < list.length; i++) list[i].id: i,
    };
    int bySource(Customer a, Customer b) =>
        (order[a.id] ?? 0).compareTo(order[b.id] ?? 0);

    switch (_sort) {
      case BoothSort.wikiOrder:
        break;
      case BoothSort.nameAZ:
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case BoothSort.nameZA:
        out.sort((a, b) => b.name.compareTo(a.name));
        break;
      case BoothSort.stayShortest:
        out.sort((a, b) {
          final c = _stayMin(a).compareTo(_stayMin(b));
          return c != 0 ? c : bySource(a, b);
        });
        break;
      case BoothSort.stayLongest:
        out.sort((a, b) {
          final c = _stayMax(b).compareTo(_stayMax(a));
          return c != 0 ? c : bySource(a, b);
        });
        break;
      case BoothSort.incomeBestExpected:
        out.sort((a, b) {
          final c = _expectedIncomeEvery5Min(
            b,
          ).compareTo(_expectedIncomeEvery5Min(a));
          return c != 0 ? c : bySource(a, b);
        });
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
                value: BoothSort.wikiOrder,
                child: Text('Game order'),
              ),
              PopupMenuItem(value: BoothSort.nameAZ, child: Text('Name (A–Z)')),
              PopupMenuItem(value: BoothSort.nameZA, child: Text('Name (Z–A)')),
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
              SearchField(
                hintText: 'Search booth owners…',
                onChanged: (v) => setState(() => _query = v),
              ),
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
                    if (total > 0)
                      TextButton(
                        onPressed: () async {
                          await store.setManyUnlocked(
                            _bucketCustomers,
                            sorted.map((c) => c.id),
                            unlocked != total,
                          );
                          if (mounted) setState(() {});
                        },
                        child: Text(
                          unlocked == total ? 'Uncheck all' : 'Check all',
                        ),
                      ),
                  ],
                ),
              ),

              _buildFishFilters(context),

              const Divider(height: 1),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final crossAxisCount = (cons.maxWidth / 200).floor().clamp(
                      1,
                      4,
                    );
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        // A tile holds only a name, so give it a fixed row
                        // height instead of forcing it square.
                        mainAxisExtent: 56,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  c.name,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
