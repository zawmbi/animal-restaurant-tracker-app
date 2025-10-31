import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../shared/data/unlocked_store.dart';
import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/money_bag.dart';

import '../model/data/facilities_repository.dart';
import '../model/facility.dart';
import '../../search/ui/global_search_page.dart';
import 'facility_detail_page.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final repo = FacilitiesRepository.instance;
  final store = UnlockedStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilities'),
        actions: [
          IconButton(
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline, size: 36),
                  const SizedBox(height: 8),
                  const Text('Failed to load facilities',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final facilities = snap.data ?? const <Facility>[];
          if (facilities.isEmpty) {
            return const Center(
              child: Text(
                'No facilities found.\nCheck assets/data/facilities.json in pubspec.yaml.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // ---------- Exclusive partitioning ----------
          bool isCourtyard(Facility f) =>
              f.area == FacilityArea.courtyard ||
              f.area == FacilityArea.courtyard_concert ||
              f.area == FacilityArea.courtyard_pets;

          bool hasPhrase(Facility f, bool Function(String) test) {
            final s = '${f.name} ${f.group} ${f.series ?? ''} ${f.description ?? ''}'
                .toLowerCase();
            return test(s);
          }

          bool isFishingPond(Facility f) =>
              hasPhrase(f, (s) => s.contains('fishing pond') || (s.contains('fishing') && s.contains('pond')));

          bool isVegetableGarden(Facility f) =>
              hasPhrase(f, (s) => s.contains('vegetable garden') || s.contains('veggie garden'));

          // Buckets
          final fishingPond = <Facility>[];
          final vegGarden   = <Facility>[];
          final garden      = <Facility>[];
          final restaurant  = <Facility>[];
          final courtyard   = <Facility>[];
          final terrace     = <Facility>[];
          final buffet      = <Facility>[];
          final takeout     = <Facility>[];
          final kitchen     = <Facility>[];

          // Deterministic, mutually exclusive assignment
          for (final f in facilities) {
            if (isFishingPond(f)) {
              fishingPond.add(f);
            } else if (isVegetableGarden(f)) {
              vegGarden.add(f);
            } else if (f.area == FacilityArea.garden) {
              garden.add(f);
            } else if (f.area == FacilityArea.restaurant) {
              restaurant.add(f);
            } else if (isCourtyard(f)) {
              courtyard.add(f);
            } else if (f.area == FacilityArea.terrace) {
              terrace.add(f);
            } else if (f.area == FacilityArea.buffet) {
              buffet.add(f);
            } else if (f.area == FacilityArea.takeout) {
              takeout.add(f);
            } else if (f.area == FacilityArea.kitchen) {
              kitchen.add(f);
            }
          }

          // ---------- Earnings (12h minimum for all purchased) ----------
          final MoneyBag total12h = EarningsCalculator.minimumOverHours(
            facilities: facilities,
            isPurchased: (id) => store.isUnlocked('facility_purchased', id),
            hours: 12,
          );
          final perHour = total12h / 12.0;

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Summary card (uses CardTheme)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Minimum Earnings (All Purchased)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('• 12-hour total:  ${total12h.toString()}'),
                          const SizedBox(height: 4),
                          Text('• Avg per hour:   ${perHour.toString()}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sections — exclusive, in requested order
                  if (fishingPond.isNotEmpty)
                    _section(context, 'Fishing Pond', fishingPond),
                  if (garden.isNotEmpty)
                    _section(context, 'Garden', garden),
                  if (vegGarden.isNotEmpty)
                    _section(context, 'Vegetable Garden', vegGarden),

                  if (restaurant.isNotEmpty)
                    _section(context, 'Restaurant', restaurant),
                  if (courtyard.isNotEmpty)
                    _section(context, 'Courtyard', courtyard),
                  if (terrace.isNotEmpty)
                    _section(context, 'Terrace', terrace),
                  if (buffet.isNotEmpty)
                    _section(context, 'Buffet', buffet),
                  if (takeout.isNotEmpty)
                    _section(context, 'Takeout', takeout),
                  if (kitchen.isNotEmpty)
                    _section(context, 'Kitchen', kitchen),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _section(BuildContext context, String title, List<Facility> list) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,     // EXACTLY 3 per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0, // square tiles
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              final purchased = store.isUnlocked('facility_purchased', f.id);
              return _FacilityTile(
                label: f.name,
                isPurchased: purchased,
                onCheckChanged: (v) =>
                    store.setUnlocked('facility_purchased', f.id, v),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FacilityDetailPage(facility: f)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.label,
    required this.isPurchased,
    required this.onCheckChanged,
    required this.onTap,
  });

  final String label;
  final bool isPurchased;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Card styling comes from global CardTheme (rounded corners, green border, cream bg)
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Center label that wraps/shrinks as needed
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: AutoSizeText(
                    label,
                    maxLines: 6,
                    wrapWords: false,
                    minFontSize: 10,
                    stepGranularity: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            // Checkbox top-right (styled by global CheckboxTheme)
            Positioned(
              top: 4,
              right: 4,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: isPurchased,
                  onChanged: (v) => onCheckChanged(v ?? false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
