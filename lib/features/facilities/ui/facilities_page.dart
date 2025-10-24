import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/facilities_repository.dart';
import '../model/facility.dart';
import 'facility_detail_page.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final repo = FacilitiesRepository.instance;
  final store = UnlockedStore.instance; // uses key 'facility_purchased'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facilities')),
      body: FutureBuilder<List<Facility>>(
        future: repo.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final f = list[i];
                    final purchased = store.isUnlocked('facility_purchased', f.id);
                    return EntityChip(
                      label: f.name,
                      checked: purchased,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FacilityDetailPage(facility: f)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}