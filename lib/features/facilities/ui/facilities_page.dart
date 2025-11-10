import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';
import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
// ignore: unused_import
import '../data/facilities_repository.dart' hide FacilitiesRepository;
import '../model/facility.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final repo = FacilitiesRepository.instance;
  final store = UnlockedStore.instance; // bucket: 'facility'

  FacilityArea? _selectedScene; // enum now
  String? _selectedTheme;       // theme/series stays String

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facilities')),
      body: FutureBuilder<List<Facility>>(
        future: repo.all(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load facilities:\n${snap.error}', textAlign: TextAlign.center),
            );
          }

          final all = (snap.data ?? const <Facility>[]);

          // Scenes (areas) excluding Courtyard variants
          final scenes = _scenesFor(all);
          _selectedScene ??= scenes.isNotEmpty ? scenes.first : null;

          // Themes for selected scene
          final themes = _themesFor(all, _selectedScene);

          // Filtered list for content
          final filtered = all.where((f) {
            if (_selectedScene != null && f.area != _selectedScene) return false;
            if (_selectedTheme != null && (f.series ?? '') != _selectedTheme) return false;
            return true;
          }).toList();

          // Group by 'group'
          final groups = _groupBy<String, Facility>(filtered, (f) => f.group);

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return Column(
                children: [
                  // ---------- X axis: Scenes (horizontal chips) ----------
                  _ScenesBar(
                    scenes: scenes,
                    selected: _selectedScene,
                    onSelect: (s) => setState(() {
                      _selectedScene = s;
                      _selectedTheme = null; // reset theme on scene change
                    }),
                  ),
                  const SizedBox(height: 8),

                  // ---------- Y axis + Content ----------
                  Expanded(
                    child: Row(
                      children: [
                        // Y axis: Theme rail
                        _ThemeRail(
                          themes: themes,
                          selected: _selectedTheme,
                          onSelect: (t) => setState(() => _selectedTheme = t),
                        ),

                        const VerticalDivider(width: 1),

                        // Content list grouped by facility.group
                        Expanded(
                          child: (groups.isEmpty)
                              ? const Center(child: Text('No facilities match.'))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  itemCount: groups.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final entry = groups[i];
                                    final groupName = entry.key;
                                    final items = entry.value;

                                    // Sort: unlocked first, then name
                                    items.sort((a, b) {
                                      final ua = store.isUnlocked('facility', a.id);
                                      final ub = store.isUnlocked('facility', b.id);
                                      if (ua != ub) return ua ? -1 : 1;
                                      return a.name.compareTo(b.name);
                                    });

                                    return _FacilityGroupSection(
                                      title: groupName,
                                      items: items,
                                      store: store,
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
          );
        },
      ),
    );
  }

  // ---------- helpers ----------

  // Build the list of scenes (FacilityArea) to show, excluding courtyard variants.
  List<FacilityArea> _scenesFor(List<Facility> all) {
    final excluded = {
      FacilityArea.courtyard,
      FacilityArea.courtyard_concert,
      FacilityArea.courtyard_pets,
    };
    final set = <FacilityArea>{};
    for (final f in all) {
      if (!excluded.contains(f.area)) set.add(f.area);
    }
    final list = set.toList()
      ..sort((a, b) => _areaOrder(a).compareTo(_areaOrder(b)));
    return list;
  }

  // Stable order with Restaurant first; the rest alphabetical by enum name.
  int _areaOrder(FacilityArea a) {
    if (a == FacilityArea.restaurant) return -9999;
    return a.name.compareTo(FacilityArea.restaurant.name);
  }

  // Themes for the selected scene.
  List<String> _themesFor(List<Facility> all, FacilityArea? selectedScene) {
    if (selectedScene == null) return const <String>[];
    final set = <String>{};
    for (final f in all) {
      if (f.area != selectedScene) continue;
      final theme = (f.series ?? '').trim();
      if (theme.isNotEmpty) set.add(theme);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Stable groupBy that keeps insertion order of keys
  List<MapEntry<K, List<V>>> _groupBy<K, V>(List<V> list, K Function(V) keyFn) {
    final map = <K, List<V>>{};
    final order = <K>[];
    for (final v in list) {
      final k = keyFn(v);
      map.putIfAbsent(k, () {
        order.add(k);
        return <V>[];
      }).add(v);
    }
    return order.map((k) => MapEntry(k, map[k]!)).toList();
  }
}

// ======================= UI bits =======================

class _ScenesBar extends StatelessWidget {
  const _ScenesBar({
    required this.scenes,
    required this.selected,
    required this.onSelect,
  });

  final List<FacilityArea> scenes;
  final FacilityArea? selected;
  final ValueChanged<FacilityArea> onSelect;

  String _label(FacilityArea a) {
    // Title-case from enum name (kitchen -> Kitchen, takeout -> Takeout, etc.)
    return a.name
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final scene = scenes[i];
          final isSel = selected == scene;
          return ChoiceChip(
            label: Text(_label(scene)),
            selected: isSel,
            onSelected: (_) => onSelect(scene),
          );
        },
      ),
    );
  }
}

class _ThemeRail extends StatelessWidget {
  const _ThemeRail({required this.themes, required this.selected, required this.onSelect});
  final List<String> themes; // e.g. ['Log Scenery','Toy City',...]
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          // "All" button
          ListTile(
            dense: true,
            title: const Text('All', style: TextStyle(fontWeight: FontWeight.w600)),
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              itemCount: themes.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final t = themes[i];
                return ListTile(
                  dense: true,
                  title: Text(t),
                  selected: selected == t,
                  onTap: () => onSelect(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityGroupSection extends StatelessWidget {
  const _FacilityGroupSection({required this.title, required this.items, required this.store});
  final String title;
  final List<Facility> items;
  final UnlockedStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, c) {
                // Responsive grid: ~160px tiles
                final crossAxisCount = (c.maxWidth / 160).floor().clamp(1, 6);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final f = items[i];
                    final checked = store.isUnlocked('facility', f.id);
                    return _FacilityTile(
                      facility: f,
                      checked: checked,
                      onChanged: (v) => store.setUnlocked('facility', f.id, v),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({required this.facility, required this.checked, required this.onChanged});
  final Facility facility;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    facility.name,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: checked,
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
