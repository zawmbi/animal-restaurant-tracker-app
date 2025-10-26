import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/money_bag.dart';
import '../data/facilities_repository.dart';
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
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Text('No facilities found.\nCheck assets/data/facilities.json in pubspec.yaml.',
                  textAlign: TextAlign.center),
            );
          }

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              // Always compute 12h minimum + show avg/hour (total ÷ 12)
              final MoneyBag total12h = EarningsCalculator.minimumOverHours(
                facilities: facilities,
                isPurchased: (id) => store.isUnlocked('facility_purchased', id),
                hours: 12,
              );
              final perHour = total12h / 12.0;

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Minimum Earnings (All Purchased)',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('• 12-hour total:  ${total12h.toString()}'),
                          const SizedBox(height: 4),
                          Text('• Avg per hour:   ${perHour.toString()}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                    ),
                    itemCount: facilities.length,
                    itemBuilder: (context, i) {
                      final f = facilities[i];
                      final purchased = store.isUnlocked('facility_purchased', f.id);
                      return EntityChip(
                        label: f.name,
                        checked: purchased,
                        showCheckbox: true,
                        onCheckChanged: (v) =>
                            store.setUnlocked('facility_purchased', f.id, v),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FacilityDetailPage(facility: f)),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
