// buildTerracePayProjection over the real terrace data.
//
// Like income_repository_test.dart, this needs the Flutter asset bundle:
// IncomeRepository and FacilitiesRepository both read through
// JsonLoader -> rootBundle, so it runs under `flutter test` and only there.
//
// The counting and ceiling figures below are sums over income.json and match
// docs/economy-report.md §7. The uplift arithmetic is checked against hand
// calculations, because it is the number the facility detail page puts in
// front of the player.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/economy/data/income_repository.dart';
import 'package:animal_restaurant_tracker/features/economy/logic/terrace_pay_projection.dart';
import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart';
import 'package:animal_restaurant_tracker/features/facilities/model/facility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final income = IncomeRepository.instance;
  late List<Facility> terrace;

  setUpAll(() async {
    await income.ensureLoaded();
    terrace = await FacilitiesRepository.instance.byArea(FacilityArea.terrace);
  });

  Facility facilityById(String id) => terrace.firstWhere((f) => f.id == id);

  group('which facilities pay', () {
    test('89 terrace facilities carry a pay bonus, all in three groups', () {
      final pay = terrace.where((f) {
        return TerracePayEffect.fromEntries(income.forFacility(f.id)).isEmpty ==
            false;
      }).toList();

      expect(pay.length, 89);
      expect(
        pay.map((f) => f.group).toSet(),
        <String>{'Gathering Table', 'Table 1', 'Table 2'},
      );
      // And the group constant agrees with what the data actually contains.
      expect(pay.map((f) => f.group).toSet(), kTerracePayGroups);
    });

    test('a telescope pays through another channel and is not counted', () {
      final effect =
          TerracePayEffect.fromEntries(income.forFacility('old_telescope'));
      expect(effect.isEmpty, isTrue);
    });

    test('owning everything reaches the ceilings in the economy report', () {
      final all = terrace.map((f) => f.id).toSet();
      final p = buildTerracePayProjection(
        facility: facilityById('natural_scenery'),
        terraceFacilities: terrace,
        unlockedIds: all,
        income: income,
      );

      expect(p.ownedFlatCod, 13384000);
      expect(p.ownedPercent, 356);
      expect(p.ownedCount, 89);
      expect(p.totalCount, 89);
    });
  });

  group('what one more table adds', () {
    test('with an empty terrace, a +5% table is a 5% raise', () {
      final p = buildTerracePayProjection(
        facility: facilityById('natural_scenery'),
        terraceFacilities: terrace,
        unlockedIds: const <String>{},
        income: income,
      );

      expect(p.effect.percent, 5);
      expect(p.ownedPercent, 0);
      expect(p.percentUpliftFraction, closeTo(0.05, 1e-12));
    });

    test('the same table is worth far less once the terrace is built up', () {
      // Owned +150%, so a customer already pays 2.5x. Adding 5 points takes
      // that to 2.55x, which is a 2% raise on current takings — not 5%.
      // This gap is the entire reason the page shows the computed figure
      // rather than the number printed on the facility.
      const p = TerracePayProjection(
        ownedFlatCod: 0,
        ownedPercent: 150,
        ownedCount: 20,
        totalCount: 89,
        effect: TerracePayEffect(percent: 5),
        alreadyUnlocked: false,
      );

      expect(p.afterPercent, 155);
      expect(p.percentUpliftFraction, closeTo(0.02, 1e-12));
    });

    test('an already-unlocked table adds nothing and says so', () {
      final p = buildTerracePayProjection(
        facility: facilityById('natural_scenery'),
        terraceFacilities: terrace,
        unlockedIds: const <String>{'natural_scenery'},
        income: income,
      );

      expect(p.alreadyUnlocked, isTrue);
      expect(p.addedPercent, 0);
      expect(p.addedFlatCod, 0);
      expect(p.percentUpliftFraction, isNull);
      // It is counted in the totals rather than added to them.
      expect(p.ownedPercent, 5);
      expect(p.afterPercent, 5);
    });

    test('a flat table has no percentage uplift to report', () {
      final p = buildTerracePayProjection(
        facility: facilityById('candy_feast'),
        terraceFacilities: terrace,
        unlockedIds: const <String>{},
        income: income,
      );

      expect(p.effect.flatCod, 200000);
      expect(p.effect.percent, 0);
      expect(p.percentUpliftFraction, isNull);
      expect(p.addedFlatCod, 200000);
    });
  });

  group('turning the uplift into cod', () {
    test('applies the uplift to an observed gather', () {
      const p = TerracePayProjection(
        ownedFlatCod: 0,
        ownedPercent: 150,
        ownedCount: 20,
        totalCount: 89,
        effect: TerracePayEffect(percent: 5),
        alreadyUnlocked: false,
      );

      // 2% of a 1,000,000 cod gather.
      expect(p.extraCodPerGather(1000000), closeTo(20000, 1e-6));
    });

    test('says nothing without an observation', () {
      const p = TerracePayProjection(
        ownedFlatCod: 0,
        ownedPercent: 150,
        ownedCount: 20,
        totalCount: 89,
        effect: TerracePayEffect(percent: 5),
        alreadyUnlocked: false,
      );

      expect(p.extraCodPerGather(0), isNull);
    });

    test('says nothing for a flat table, which has no base-free answer', () {
      // A flat bonus is per customer, and how many customers a terrace gather
      // brings is unpublished, so there is no honest conversion.
      const p = TerracePayProjection(
        ownedFlatCod: 1000000,
        ownedPercent: 0,
        ownedCount: 5,
        totalCount: 89,
        effect: TerracePayEffect(flatCod: 200000),
        alreadyUnlocked: false,
      );

      expect(p.extraCodPerGather(1000000), isNull);
    });
  });
}
