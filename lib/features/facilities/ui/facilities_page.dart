import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/data/unlocked_store.dart';
import '../model/facility.dart';
import '../../search/ui/global_search_page.dart';
import '../../facilities/model/data/facilities_repository.dart';
import 'facility_detail_page.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final repo = FacilitiesRepository.instance;
  final store = UnlockedStore.instance;

  /// Cache the load so we don’t refetch on every rebuild.
  late final Future<List<Facility>> _facilitiesFuture;

  /// Per-area sort mode: 'Facility Type' (default) or 'Series'
  final Map<String, String> _areaSortMode = {};
  /// Per-area expanded state for groups: area -> (group -> expanded?)
  final Map<String, Map<String, bool>> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _facilitiesFuture = repo.all();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamLight,
      appBar: AppBar(
        title: const Text('Facilities'),
        backgroundColor: kCreamLight,
        foregroundColor: kBrownDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Facility>>(
        future: _facilitiesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          final facilities = snap.data ?? const <Facility>[];
          // Top-level: Areas
          final byArea = _groupBySingle(facilities, (f) => _pretty(f.area.name));

          return CustomScrollView(
            slivers: [
              for (final entry in byArea.entries)
                ..._buildAreaSlivers(context, entry.key, entry.value),
            ],
          );
        },
      ),
    );
  }

  /// Build slivers for one Area: pinned area header + grouped sections
  List<Widget> _buildAreaSlivers(
    BuildContext context,
    String areaLabel,
    List<Facility> areaFacilities,
  ) {
    final mode = _areaSortMode[areaLabel] ?? 'Facility Type';
    final grouped = _sortWithinArea(areaFacilities, mode).entries.toList();

    // Ensure expansion state map exists for this area, default groups to open
    final areaMap = _expandedGroups.putIfAbsent(areaLabel, () => {});
    for (final e in grouped) {
      areaMap.putIfAbsent(e.key, () => true);
    }

    return [
      // Pinned Area header with Sort + Open/Close all
      SliverPersistentHeader(
        pinned: true,
        delegate: _HeaderBarDelegate(
          minHeight: 56,
          maxHeight: 56,
          child: Container(
            color: kCreamDark,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(areaLabel,
                    style: const TextStyle(
                      color: kBrownDark,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 12),
                const Text('•', style: TextStyle(color: kBrownDark)),
                const SizedBox(width: 12),
                const Text('Sort by:',
                    style: TextStyle(
                      color: kBrownDark,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: mode,
                  items: const [
                    DropdownMenuItem(value: 'Facility Type', child: Text('Facility Type')),
                    DropdownMenuItem(value: 'Series', child: Text('Series')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _areaSortMode[areaLabel] = v);
                  },
                  dropdownColor: kCreamLight,
                  style: const TextStyle(color: kBrownDark),
                  iconEnabledColor: kBrownDark,
                  underline: const SizedBox.shrink(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    for (final e in grouped) {
                      _expandedGroups[areaLabel]![e.key] = true;
                    }
                  }),
                  child: const Text('Open all'),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => setState(() {
                    for (final e in grouped) {
                      _expandedGroups[areaLabel]![e.key] = false;
                    }
                  }),
                  child: const Text('Close all'),
                ),
              ],
            ),
          ),
        ),
      ),

      // Each group inside the Area (sticky group header + grid)
      for (final e in grouped) ..._buildGroupSlivers(context, areaLabel, e.key, e.value),
    ];
  }

  // ─────────────────────────────
  // Sorting logic within an Area
  // ─────────────────────────────
  Map<String, List<Facility>> _sortWithinArea(List<Facility> facilities, String mode) {
    switch (mode) {
      case 'Series':
        return _groupBySingle(facilities, (f) => f.series ?? 'Uncategorized');
      case 'Facility Type':
      default:
        return _groupBySingle(facilities, (f) => f.group);
    }
  }

  // Sticky group section (header + grid when expanded)
  List<Widget> _buildGroupSlivers(
    BuildContext context,
    String areaLabel,
    String groupTitle,
    List<Facility> list,
  ) {
    final expanded = _expandedGroups[areaLabel]?[groupTitle] ?? true;

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _SectionHeaderDelegate(
          minHeight: 44,
          maxHeight: 44,
          title: groupTitle,
          expanded: expanded,
          onTap: () => setState(() {
            final current = _expandedGroups[areaLabel] ?? {};
            current[groupTitle] = !(current[groupTitle] ?? true);
            _expandedGroups[areaLabel] = current;
          }),
        ),
      ),
      if (expanded)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9, // a bit taller so labels have room
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final f = list[index];
                final isUnlocked = store.isUnlocked('facility_purchased', f.id);
                return _FacilityTile(
                  key: ValueKey(f.id),
                  f: f,
                  isUnlocked: isUnlocked,
                  onCheckChanged: (v) async {
                    final result = store.setUnlocked('facility_purchased', f.id, v);
                    if (result is Future) await result;
                    // Rebuild so this tile re-reads isUnlocked
                    setState(() {});
                  },
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FacilityDetailPage(facility: f)),
                    );
                  },
                );
              },
              childCount: list.length,
            ),
          ),
        ),
    ];
  }

  // ─────────────────────────────
  // Utility grouping helpers
  // ─────────────────────────────
  Map<String, List<Facility>> _groupBySingle(
    List<Facility> items,
    String Function(Facility) key,
  ) {
    final Map<String, List<Facility>> map = {};
    for (final f in items) {
      final k = key(f);
      map.putIfAbsent(k, () => []).add(f);
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  String _pretty(String text) => text
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────
// Sliver header delegates
// ─────────────────────────────
class _HeaderBarDelegate extends SliverPersistentHeaderDelegate {
  _HeaderBarDelegate({required this.minHeight, required this.maxHeight, required this.child});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight >= minHeight ? maxHeight : minHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand( // ensure geometry matches paint size
      child: Material(
        elevation: overlapsContent ? 2 : 0,
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderBarDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.child != child;
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final double minHeight;
  final double maxHeight;
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight >= minHeight ? maxHeight : minHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: kCreamLight,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(color: kBrownDark, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, color: kBrownDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate old) =>
      old.title != title ||
      old.expanded != expanded ||
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight;
}

// ─────────────────────────────
// Facility tile card
// ─────────────────────────────
class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    super.key,
    required this.f,
    required this.isUnlocked,
    required this.onCheckChanged,
    required this.onTap,
  });

  final Facility f;
  final bool isUnlocked;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(12));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: kCreamDark,
            borderRadius: radius,
            border: Border.all(color: kGreen, width: 3),
          ),
          child: Stack(
            children: [
              // Name centered with safe padding
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                  child: Text(
                    f.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kBrownDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Checkbox in the top-right
              Positioned(
                top: 4,
                right: 4,
                child: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: isUnlocked,
                    onChanged: (v) => onCheckChanged(v ?? false),
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => states.contains(MaterialState.selected) ? kGreen : Colors.white,
                    ),
                    side: const BorderSide(color: kGreen, width: 3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
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
