import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

  // Top-level always shows Areas
  final Map<String, bool> _expandedAreas = {};
  final Map<String, String> _areaSortMode = {}; // per-area sort
  final Map<String, Map<String, bool>> _expandedGroups = {}; // area -> group -> expanded?

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
        future: repo.all(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final facilities = snap.data ?? const <Facility>[];
          final byArea = _groupBySingle(facilities, (f) => _pretty(f.area.name));

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return ListView(
                children: byArea.entries.map((e) {
                  final area = e.key;
                  final items = e.value;
                  final expanded = _expandedAreas[area] ?? false;
                  final sortMode = _areaSortMode[area] ?? 'Facility Type';
                  final grouped = _sortWithinArea(items, sortMode);
                  _expandedGroups.putIfAbsent(area, () => {for (final g in grouped.keys) g: true});

                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: const ExpansionTileThemeData(
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        textColor: kBrownDark,
                        collapsedTextColor: kBrownDark,
                        iconColor: kBrownDark,
                        collapsedIconColor: kBrownDark,
                      ),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: expanded,
                      onExpansionChanged: (v) =>
                          setState(() => _expandedAreas[area] = v),
                      title: Text(
                        area,
                        style: const TextStyle(
                          color: kBrownDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      children: [
                        _sortBar(context, area, sortMode),
                        const Divider(height: 1, color: kBrownDark),
                        for (final sub in grouped.entries)
                          _groupSection(context, area, sub.key, sub.value),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────
  // Sorting logic within an Area
  // ─────────────────────────────
  Map<String, List<Facility>> _sortWithinArea(
      List<Facility> facilities, String mode) {
    switch (mode) {
      case 'Series':
        return _groupBySingle(facilities, (f) => f.series ?? 'Uncategorized');
      case 'Facility Type':
      default:
        return _groupBySingle(facilities, (f) => f.group);
    }
  }

  Widget _sortBar(BuildContext context, String area, String selected) {
    const sortOptions = ['Facility Type', 'Series'];
    return Container(
      color: kCreamDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kBrownDark,
            ),
          ),
          DropdownButton<String>(
            value: selected,
            items: sortOptions
                .map((s) => DropdownMenuItem<String>(
                      value: s,
                      child: Text(s, style: const TextStyle(color: kBrownDark)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _areaSortMode[area] = v ?? 'Facility Type'),
            dropdownColor: kCreamLight,
            style: const TextStyle(color: kBrownDark),
            iconEnabledColor: kBrownDark,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Expandable group within an area
  // ─────────────────────────────
  Widget _groupSection(
      BuildContext context, String area, String group, List<Facility> list) {
    final expanded = _expandedGroups[area]?[group] ?? true;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (v) {
          setState(() {
            _expandedGroups[area]?[group] = v;
          });
        },
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            group,
            style: const TextStyle(
              color: kBrownDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                final isUnlocked =
                    store.isUnlocked('facility_purchased', f.id);
                return _FacilityTile(
                  f: f,
                  isUnlocked: isUnlocked,
                  onCheckChanged: (v) =>
                      store.setUnlocked('facility_purchased', f.id, v),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FacilityDetailPage(facility: f),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Utility grouping helpers
  // ─────────────────────────────
  Map<String, List<Facility>> _groupBySingle(
      List<Facility> items, String Function(Facility) key) {
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
// Facility tile card
// ─────────────────────────────
class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
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
    return Container(
      decoration: BoxDecoration(
        color: kCreamDark,
        borderRadius: radius,
        border: Border.all(color: kGreen, width: 3),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, left: 8, right: 8),
                  child: Center(
                    child: AutoSizeText(
                      f.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      wrapWords: true,
                      minFontSize: 10,
                      stepGranularity: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kBrownDark),
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
                    value: isUnlocked,
                    onChanged: (v) => onCheckChanged(v ?? false),
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => isUnlocked ? kGreen : Colors.white,
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
