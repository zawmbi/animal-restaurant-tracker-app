import 'package:flutter/material.dart';
import '../../shared/widgets/check_all_button.dart';

import '../data/courtyard_facilities.dart';
import '../data/courtyard_repository.dart';
import 'courtyard_facility_detail_page.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';
import '../../shared/widgets/filter_drawer.dart';
import '../../shared/widgets/search_field.dart';

class CourtyardPage extends StatefulWidget {
  const CourtyardPage({super.key});

  @override
  State<CourtyardPage> createState() => _CourtyardPageState();
}

class _CourtyardPageState extends State<CourtyardPage> {
  late Future<void> _loadFuture;
  CourtyardScene _scene = CourtyardScene.courtyard;
  String? _selectedGroup;
  String? _selectedSeries;

  final _store = UnlockedStore.instance;
  static const _bucket = 'courtyard_facility_purchased';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFuture = CourtyardRepository.instance.ensureLoaded();
  }

  /// The series available inside the selected group.
  ///
  /// This used to list every series in the whole scene — 30 of them on the
  /// concert stage — most of which led nowhere: picking "Deep-sea Ballad"
  /// while the Speaker group was showing just emptied the page. Scoping it to
  /// the group means every option has something behind it, and the list is
  /// short enough to sit in a dropdown.
  List<String> _seriesOptionsFor(CourtyardRepository repo, String group) {
    final names = <String>{};
    for (final f in repo.byGroupAndSeries(group, series: null, scene: _scene)) {
      final series = f.series?.trim();
      if (series != null && series.isNotEmpty) names.add(series);
    }
    final sorted = names.toList()..sort();
    return ['All', ...sorted];
  }

  /// Lets the app-bar button open the filter panel, which lives on the
  /// Scaffold rather than in the tree below it.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _selectScene(CourtyardScene scene) {
    setState(() {
      _scene = scene;
      // Group and series names do not carry across scenes, so both reset to
      // the new scene's first tab rather than landing on an empty list.
      _selectedGroup = null;
      _selectedSeries = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold is built inside the FutureBuilder because its app bar and
    // its filter panel both need the series list, and that is only known once
    // the repository has loaded.
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Courtyard')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final repo = CourtyardRepository.instance;
        final groups = repo.availableGroups(_scene);

        if (groups.isEmpty) {
          return Center(
            child: Text('No ${_scene.label} facilities found in JSON.'),
          );
        }

        _selectedGroup ??= groups.first;

        final seriesOptions = _seriesOptionsFor(repo, _selectedGroup!);
        // The options change with the group, so a selection left over from
        // the previous one falls back to All rather than leaving the
        // dropdown holding a value it has no item for.
        if (!seriesOptions.contains(_selectedSeries)) {
          _selectedSeries = 'All';
        }

        final facilities = repo
            .byGroupAndSeries(
              _selectedGroup!,
              series: _selectedSeries == 'All' ? null : _selectedSeries,
              scene: _scene,
            )
            .where((f) => matchesQuery(
                  _query,
                  '${f.name} ${f.id} ${f.group} ${f.series ?? ''}',
                ))
            .toList();

        // Series names without the 'All' sentinel: the panel supplies that
        // itself, and uses null for it.
        final panelOptions =
            seriesOptions.where((s) => s != 'All').toList(growable: false);
        final active = _selectedSeries == 'All' ? null : _selectedSeries;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Courtyard'),
            actions: [
              if (panelOptions.isNotEmpty)
                FilterButton(
                  selected: active,
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
            ],
          ),
          endDrawer: panelOptions.isEmpty
              ? null
              : FilterDrawer(
                  title: 'Series',
                  options: panelOptions,
                  selected: active,
                  onSelect: (value) =>
                      setState(() => _selectedSeries = value ?? 'All'),
                ),
          body: Column(
            children: [
            SearchField(
              hintText: 'Search ${_scene.label.toLowerCase()} facilities…',
              onChanged: (v) => setState(() => _query = v),
            ),

            // Scene picker. The concert stage and the pet yard are reached
            // from the courtyard in the game and their data has the same
            // shape, so they are tabs here rather than pages of their own.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: CourtyardScene.values.map((scene) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(scene.label),
                      selected: scene == _scene,
                      onSelected: (_) => _selectScene(scene),
                    ),
                  );
                }).toList(),
              ),
            ),

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
                          // Series names do not carry across groups.
                          _selectedSeries = null;
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
              child: facilities.isEmpty
                  ? const Center(
                      child: Text('No facilities for this filter yet.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: facilities.length + 1,
                      itemBuilder: (context, rawIndex) {
                        if (rawIndex == 0) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: CheckAllButton(
                              bucket: _bucket,
                              ids: facilities
                                  .map((f) => f.id)
                                  .toList(),
                              groupLabel:
                                  '${_scene.label} — $_selectedGroup',
                              onApplied: (_) {
                                if (mounted) setState(() {});
                              },
                            ),
                          );
                        }
                        final index = rawIndex - 1;
                        final f = facilities[index];
                        final checked = _store.isUnlocked(
                          _bucket,
                          f.id,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
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
                                  // One line, not three: the description
                                  // is flavour text and the full thing is
                                  // on the detail page one tap away. The
                                  // Decor (Floor) group alone is 477 rows,
                                  // where two extra lines is ~17 screens.
                                  // ListTile already spaces title from
                                  // subtitle, so no SizedBox here.
                                  Text(
                                    f.description,
                                    maxLines: 1,
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
        );
      },
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
