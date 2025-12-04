import 'package:flutter/material.dart';

import '../data/courtyard_facilities.dart';
import '../data/courtyard_repository.dart';
import 'courtyard_facility_detail_page.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

class CourtyardPage extends StatefulWidget {
  const CourtyardPage({super.key});

  @override
  State<CourtyardPage> createState() => _CourtyardPageState();
}

class _CourtyardPageState extends State<CourtyardPage> {
  late Future<void> _loadFuture;
  String? _selectedGroup;
  String? _selectedSeries;

  final _store = UnlockedStore.instance;
  static const _bucket = 'courtyard_facility_purchased';

  @override
  void initState() {
    super.initState();
    _loadFuture = CourtyardRepository.instance.ensureLoaded();
  }

  List<String> _buildSeriesOptions(CourtyardRepository repo) {
    final base = repo.allSeriesSorted();
    return ['All', ...base];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courtyard'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final repo = CourtyardRepository.instance;
          final groups = repo.availableGroups();

          if (groups.isEmpty) {
            return const Center(
              child: Text('No Courtyard facilities found in JSON.'),
            );
          }

          _selectedGroup ??= groups.first;
          _selectedSeries ??= 'All';

          final seriesOptions = _buildSeriesOptions(repo);

          final facilities = repo.byGroupAndSeries(
            _selectedGroup!,
            series: _selectedSeries == 'All' ? null : _selectedSeries,
          );

          return Column(
            children: [
              // Top group tabs (Friends Board, Speaker, etc.)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: groups.map((group) {
                    final selected = group == _selectedGroup;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(group),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedGroup = group;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Series / theme list (left side)
                    Container(
                      width: 180,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: seriesOptions.length,
                        itemBuilder: (context, index) {
                          final series = seriesOptions[index];
                          final selected = _selectedSeries == series;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            title: Text(
                              series,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedSeries = series;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    // Facility cards (right side)
                    Expanded(
                      child: facilities.isEmpty
                          ? const Center(
                              child: Text('No facilities for this filter yet.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: facilities.length,
                              itemBuilder: (context, index) {
                                final f = facilities[index];
                                final checked = _store.isUnlocked(
                                  _bucket,
                                  f.id,
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CourtyardFacilityDetailPage(
                                            facility: f,
                                            bucket: _bucket,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      title: Text(f.name),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            f.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (f.requirementNote != null &&
                                              f.requirementNote!.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 4.0),
                                              child: Text(
                                                'Requirements: ${f.requirementNote}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          if (f.price.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 4.0),
                                              child: Text(
                                                _formatPriceList(f.price),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Checkbox(
                                        value: checked,
                                        onChanged: (v) {
                                          setState(() {
                                            _store.setUnlocked(
                                              _bucket,
                                              f.id,
                                              v ?? false,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatPriceList(List<CourtyardPrice> prices) {
    if (prices.isEmpty) return 'Price: Free';
    final parts = prices.map((p) {
      final label = switch (p.currency) {
        'cod' => 'Cod',
        'film' => 'Film',
        'diamond' => 'Diamond',
        _ => p.currency,
      };
      return '$label ${p.amount}';
    }).toList();

    return 'Price: ${parts.join(' + ')}';
  }
}
