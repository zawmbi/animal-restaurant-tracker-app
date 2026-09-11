// EarningsCalculator.summarize over the real income.json.
//
// This is the one economy test that needs the Flutter asset bundle:
// IncomeRepository reads through JsonLoader -> rootBundle, and summarize()
// takes the concrete repository rather than an interface, so it cannot be
// faked. `flutter test` serves assets declared in pubspec.yaml, so this works
// under `flutter test` and only there.
//
// Every expected number below is the sum of the matching channel across
// income.json, and matches the ceilings quoted in docs/economy-report.md.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/economy/data/income_repository.dart';
import 'package:animal_restaurant_tracker/features/economy/logic/earnings_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = IncomeRepository.instance;

  setUpAll(() async {
    await repo.ensureLoaded();
  });

  group('the repository', () {
    test('loads and reports when the data was transcribed', () {
      expect(repo.retrieved, isNotNull);
      expect(repo.retrieved, isNotEmpty);
    });

    test('a facility with no verified income has no entries, not a zero', () {
      expect(repo.forFacility('a_facility_that_does_not_exist'), isEmpty);
    });

    test('2,794 facilities carry at least one income effect', () {
      // 2,788 until six ids that two different facilities shared were split
      // apart. Each of those entries held both facilities' channels, so both
      // rows were credited with the other's income.
      expect(repo.facilityIdsWithIncome.length, 2794);
    });

    test('all 61 concert performers are loaded', () {
      expect(repo.performers.length, 61);
    });
  });

  group('single facilities, straight from the report', () {
    test('Stone Bowl: a 10,000 cod jar filling at 5 cod/min', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['stone_bowl'],
        repository: repo,
      );
      expect(s.facilitiesCounted, 1);
      expect(s.tipCapCod, 10000);
      expect(s.tipPerMinuteCod, 5);
      expect(s.buffetCodPerHour, 0);
    });

    test('Simple Carousel: 3,200 cod per hour, and nothing per minute', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['simple_carousel'],
        repository: repo,
      );
      expect(s.buffetCodPerHour, 3200);
      expect(s.tipPerMinuteCod, 0,
          reason: 'a per-hour buffet figure must never land in the per-minute '
              'tip total — that is the 60x bug this rewrite exists to stop');
    });

    test('Fine Oven: +95/30s is 11,400 cod per hour of play', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['fine_oven'],
        repository: repo,
      );
      expect(s.activeCodPerHour, 11400);
    });

    test('Ornate Oven: +160/30s is 19,200 cod per hour of play', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['ornate_oven'],
        repository: repo,
      );
      expect(s.activeCodPerHour, 19200);
    });

    test('Fruit Platter: +40 per purchase', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['fruit_platter'],
        repository: repo,
      );
      expect(s.codPerPurchase, 40);
    });

    test('Log Door: 95-4,800 cod per Courtyard gather, kept as a range', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['door_log_door'],
        repository: repo,
      );
      expect(s.codPerGather.min, 95);
      expect(s.codPerGather.max, 4800);
      expect(s.codPerGather.isExact, isFalse,
          reason: 'a randomised payout must not be collapsed to one number');
    });
  });

  group('summing', () {
    test('two facilities add, per the game FAQ on combined effects', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['stone_bowl', 'abacus_counter'],
        repository: repo,
      );
      expect(s.tipCapCod, 10000 + 200000);
    });

    test('a duplicate id is counted once', () {
      final one = EarningsCalculator.summarize(
        facilityIds: const <String>['stone_bowl'],
        repository: repo,
      );
      final twice = EarningsCalculator.summarize(
        facilityIds: const <String>['stone_bowl', 'stone_bowl'],
        repository: repo,
      );
      expect(twice.tipCapCod, one.tipCapCod);
      expect(twice.facilitiesCounted, 1);
    });

    test('an id with no income does not count as a facility', () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>['stone_bowl', 'not_a_facility'],
        repository: repo,
      );
      expect(s.facilitiesCounted, 1);
    });

    test('owning nothing summarises to empty, not to zeroes that look real',
        () {
      final s = EarningsCalculator.summarize(
        facilityIds: const <String>[],
        repository: repo,
      );
      expect(s.isEmpty, isTrue);
      expect(s.facilitiesCounted, 0);
      expect(s.codPerGather.isZero, isTrue);
    });
  });

  group('ceilings with everything owned', () {
    late IncomeSummary everything;

    setUpAll(() {
      everything = EarningsCalculator.summarize(
        facilityIds: repo.facilityIdsWithIncome,
        repository: repo,
      );
    });

    test('tips: 11,116 cod/min into a 3,596,000 jar', () {
      expect(everything.tipPerMinuteCod, 11116);
      expect(everything.tipCapCod, 3596000);
      // The report quotes 666,960 cod/h, which is the same number per hour.
      expect(everything.tipPerMinuteCod * 60, 666960);
    });

    test('buffet: 728,780 cod/h and 5,942 plates/day', () {
      expect(everything.buffetCodPerHour, 728780);
      expect(everything.buffetPlatesPerDay, 5942);
    });

    test('active play: 7,582,320 cod per hour of play', () {
      expect(everything.activeCodPerHour, 7582320);
    });

    test('purchases: +18,690 cod on each one', () {
      expect(everything.codPerPurchase, 18690);
    });

    test('courtyard gathers: 78,649-3,970,000 cod and 5,044-100,050 film', () {
      expect(everything.codPerGather.min, 78649);
      expect(everything.codPerGather.max, 3970000);
      expect(everything.filmPerGather.min, 5044);
      expect(everything.filmPerGather.max, 100050);
    });

    test('terrace: +13,384,000 cod flat, +356%, 171,700 per view, 36 bottles',
        () {
      expect(everything.terracePayFlatCod, 13384000);
      expect(everything.terracePayPercent, 356);
      expect(everything.codPerFlowerView, 171700);
      expect(everything.bottlesPerDay, 36);
    });

    test('takeout: +62 orders and +3,760 capacity', () {
      expect(everything.takeoutOrders, 62);
      expect(everything.takeoutCapacity, 3760);
    });

    test('gachapon: the facility rows sum to 292, above the published 286', () {
      // docs/economy-report.md flags this: the wiki's own ceiling and the sum
      // of its per-facility rows disagree, and the Bank page shows both.
      expect(everything.gachaDraws, 292);
    });

    test('concert lights sum to 56 invites, above the published ceiling of 20',
        () {
      expect(everything.concertDailyInvites, 56);
    });

    test('band profit percentages are kept per band, never pooled', () {
      expect(everything.bandProfitPercent, isNotEmpty);
      for (final entry in everything.bandProfitPercent.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, greaterThan(0));
      }
    });

    test('pet play reports the best single payout, not a sum', () {
      // Whether several Pet Paradise apparatus stack is undocumented.
      expect(everything.bestPetPlayFilm.max, lessThan(10000),
          reason: 'a summed pet-play figure would be far larger than any '
              'single apparatus pays');
      expect(everything.petPlayFacilityCount, greaterThan(1));
    });
  });
}
