// The worked examples from docs/economy-report.md, asserted.
//
// The report is the source of truth for what these numbers should be; if a
// number here changes, the report has to change with it, and vice versa. The
// unit is the whole point: a per-hour figure read as per-minute is what made
// the old Bank page overstate the buffet sixtyfold.
//
// Pure arithmetic — no assets, no bindings, no repository.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/economy/logic/earnings_calculator.dart';
import 'package:animal_restaurant_tracker/features/economy/model/currency.dart';
import 'package:animal_restaurant_tracker/features/economy/model/economy_constants.dart';
import 'package:animal_restaurant_tracker/features/economy/model/money_bag.dart';

void main() {
  group('tip jar', () {
    test('worked example: Stone Bowl, 5 cod/min into a 10,000 jar', () {
      // docs/economy-report.md §1.
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 10000, minutes: 60),
        300,
      );
      expect(
        EarningsCalculator.minutesToFillTipJar(perMinute: 5, capacity: 10000),
        2000,
      );
      // A 12-hour absence collects 3,600, not a full jar.
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 10000, minutes: 12 * 60),
        3600,
      );
    });

    test('the jar stops at its cap and stays there', () {
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 10000, minutes: 3000),
        10000,
      );
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 10000, minutes: 100000),
        10000,
      );
    });

    test('there is no 12-hour limit on tips — that belongs to the buffet', () {
      // A jar big enough not to fill keeps accruing past hour 12.
      final at12 = EarningsCalculator.tipsAfterMinutes(
          perMinute: 100, capacity: 1000000, minutes: 12 * 60);
      final at24 = EarningsCalculator.tipsAfterMinutes(
          perMinute: 100, capacity: 1000000, minutes: 24 * 60);
      expect(at24, greaterThan(at12));
      expect(at24, 144000);
    });

    test('a jar with no cap accrues without limit', () {
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 0, minutes: 100),
        500,
      );
    });

    test('no rate or no time pays nothing, and never a negative', () {
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 0, capacity: 10000, minutes: 60),
        0,
      );
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: 5, capacity: 10000, minutes: 0),
        0,
      );
      expect(
        EarningsCalculator.tipsAfterMinutes(
            perMinute: -5, capacity: 10000, minutes: 60),
        0,
      );
    });

    test('a jar that never fills reports null, not infinity', () {
      expect(
        EarningsCalculator.minutesToFillTipJar(perMinute: 0, capacity: 10000),
        isNull,
      );
      expect(
        EarningsCalculator.minutesToFillTipJar(perMinute: 5, capacity: 0),
        isNull,
      );
    });
  });

  group('buffet', () {
    test('worked example: Simple Carousel at 3,200 cod/h', () {
      // docs/economy-report.md §2.
      expect(EarningsCalculator.buffetAfterHours(perHour: 3200, hours: 3), 9600);
      expect(EarningsCalculator.buffetAdBonus(9600), 3840);
    });

    test('accrual stops at 12 hours', () {
      expect(
        EarningsCalculator.buffetAfterHours(perHour: 3200, hours: 20),
        38400,
      );
      expect(
        EarningsCalculator.buffetAfterHours(perHour: 3200, hours: 12),
        EarningsCalculator.buffetAfterHours(perHour: 3200, hours: 200),
      );
      expect(EconomyConstants.buffetMaxAccrualHours, 12);
    });

    test('worked example: every buffet facility owned tops out at 8,745,360',
        () {
      // 728,780 cod/h is the sum of every buffetCodPerHour row in income.json.
      expect(
        EarningsCalculator.buffetAfterHours(perHour: 728780, hours: 20),
        12 * 728780,
      );
    });

    test('each working friend adds 10% for four hours only', () {
      const perHour = 1000.0;
      final none = EarningsCalculator.buffetAfterHours(
          perHour: perHour, hours: 12, friendsWorking: 0);
      final two = EarningsCalculator.buffetAfterHours(
          perHour: perHour, hours: 12, friendsWorking: 2);

      expect(none, 12000);
      // 12,000 base + 2 friends x 10% x 1,000 x 4 hours.
      expect(two, 12000 + 800);
    });

    test('the friend bonus is capped by the shorter of the two windows', () {
      // Away two hours: the friend bonus only applies for those two hours.
      final short = EarningsCalculator.buffetAfterHours(
          perHour: 1000, hours: 2, friendsWorking: 1);
      expect(short, 2000 + 200);
    });

    test('the ad is 40% of what is banked, capped at 1,000,000', () {
      expect(EarningsCalculator.buffetAdBonus(2000000), 800000);
      expect(EarningsCalculator.buffetAdBonus(3000000), 1000000);
      expect(EarningsCalculator.buffetAdBonus(0), 0);
      expect(EarningsCalculator.buffetAdBonus(-1), 0);
    });

    test('the ad break-even is 2,500,000 cod banked', () {
      expect(EarningsCalculator.buffetAdBreakEvenCod(), 2500000);
      // Self-consistency with the two constants the report cites.
      expect(
        EconomyConstants.buffetAdBonusCapCod /
            EconomyConstants.buffetAdBonusFraction,
        2500000,
      );
      // Exactly at break-even the ad is worth its cap and no more.
      expect(EarningsCalculator.buffetAdBonus(2500000), 1000000);
    });

    test('nothing banked pays nothing', () {
      expect(EarningsCalculator.buffetAfterHours(perHour: 0, hours: 12), 0);
      expect(EarningsCalculator.buffetAfterHours(perHour: 3200, hours: 0), 0);
    });
  });

  group('expected value of a random payout', () {
    test('worked example: Traditional Popcorn, with its unverified odds', () {
      // 12% x 100 cod + 88% x 10 plates.
      final bag = EarningsCalculator.expectedValue(<ChanceOutcome>[
        const ChanceOutcome(
            currency: MoneyCurrency.cod, amount: 100, chance: 0.12),
        const ChanceOutcome(
            currency: MoneyCurrency.plates, amount: 10, chance: 0.88),
      ]);

      expect(bag, isNotNull);
      expect(bag!.get(MoneyCurrency.cod), closeTo(12, 1e-9));
      expect(bag.get(MoneyCurrency.plates), closeTo(8.8, 1e-9));
    });

    test('an unpublished probability returns null, never a number', () {
      // 134 of 140 booths have no published odds. Inventing one would be worse
      // than showing the min and the max.
      final bag = EarningsCalculator.expectedValue(<ChanceOutcome>[
        const ChanceOutcome(
            currency: MoneyCurrency.plates, amount: 10, chance: null),
        const ChanceOutcome(
            currency: MoneyCurrency.cod, amount: 100, chance: null),
      ]);
      expect(bag, isNull);
    });

    test('one missing probability poisons the whole table', () {
      final bag = EarningsCalculator.expectedValue(<ChanceOutcome>[
        const ChanceOutcome(
            currency: MoneyCurrency.cod, amount: 100, chance: 0.5),
        const ChanceOutcome(
            currency: MoneyCurrency.plates, amount: 10, chance: null),
      ]);
      expect(bag, isNull);
    });

    test('probabilities that do not sum to 1 mean an incomplete table', () {
      expect(
        EarningsCalculator.expectedValue(<ChanceOutcome>[
          const ChanceOutcome(
              currency: MoneyCurrency.cod, amount: 100, chance: 0.5),
        ]),
        isNull,
      );
      expect(
        EarningsCalculator.expectedValue(<ChanceOutcome>[
          const ChanceOutcome(
              currency: MoneyCurrency.cod, amount: 100, chance: 0.7),
          const ChanceOutcome(
              currency: MoneyCurrency.plates, amount: 10, chance: 0.7),
        ]),
        isNull,
      );
    });

    test('an empty table has no expected value', () {
      expect(EarningsCalculator.expectedValue(const <ChanceOutcome>[]), isNull);
    });

    test('a non-money outcome is skipped, not counted as cod', () {
      // Booth owners can pay star rating instead of a currency.
      final bag = EarningsCalculator.expectedValue(<ChanceOutcome>[
        const ChanceOutcome(
            currency: MoneyCurrency.cod, amount: 100, chance: 0.5),
        const ChanceOutcome(currency: null, amount: 999999, chance: 0.5),
      ]);
      expect(bag, isNotNull);
      expect(bag!.get(MoneyCurrency.cod), closeTo(50, 1e-9));
      expect(bag.nonZeroCurrencies, <MoneyCurrency>[MoneyCurrency.cod]);
    });
  });

  group('MoneyBag never mixes currencies', () {
    test('each currency totals separately', () {
      final bag = MoneyBag()
        ..add(MoneyCurrency.cod, 100)
        ..add(MoneyCurrency.cod, 50)
        ..add(MoneyCurrency.plates, 7);

      expect(bag.get(MoneyCurrency.cod), 150);
      expect(bag.get(MoneyCurrency.plates), 7);
      expect(bag.get(MoneyCurrency.film), 0);
      expect(bag.nonZeroCurrencies,
          <MoneyCurrency>[MoneyCurrency.cod, MoneyCurrency.plates]);
    });

    test('an empty bag is zero, not null', () {
      final bag = MoneyBag();
      expect(bag.isZero, isTrue);
      expect(bag.nonZeroCurrencies, isEmpty);
      for (final c in MoneyCurrency.values) {
        expect(bag.get(c), 0);
      }
    });

    test('scaled divides and multiplies, where the old operator/ returned null',
        () {
      final bag = MoneyBag()..add(MoneyCurrency.cod, 100);
      expect(bag.scaled(0.5).get(MoneyCurrency.cod), 50);
      expect(bag.scaled(3).get(MoneyCurrency.cod), 300);
      // The original is untouched.
      expect(bag.get(MoneyCurrency.cod), 100);
    });

    test('addBag merges without losing a currency', () {
      final a = MoneyBag()..add(MoneyCurrency.cod, 10);
      final b = MoneyBag()..add(MoneyCurrency.film, 5);
      a.addBag(b);
      expect(a.get(MoneyCurrency.cod), 10);
      expect(a.get(MoneyCurrency.film), 5);
    });
  });

  group('AmountRange', () {
    test('worked example: Log Door pays 95-4,800 cod per gather', () {
      const range = AmountRange(95, 4800);
      expect(range.min, 95);
      expect(range.max, 4800);
      expect(range.mid, 2447.5);
      expect(range.isExact, isFalse);
    });

    test('ranges add end to end', () {
      const a = AmountRange(95, 4800);
      const b = AmountRange(3, 58);
      final sum = a + b;
      expect(sum.min, 98);
      expect(sum.max, 4858);
    });

    test('an exact amount is a zero-width range', () {
      const exact = AmountRange.exact(420);
      expect(exact.isExact, isTrue);
      expect(exact.mid, 420);
    });

    test('zero is zero', () {
      expect(AmountRange.zero.isZero, isTrue);
      expect((AmountRange.zero + AmountRange.zero).isZero, isTrue);
    });

    test('scaling keeps both ends', () {
      final scaled = const AmountRange(10, 20).scaled(3);
      expect(scaled.min, 30);
      expect(scaled.max, 60);
    });
  });

  group('currency labels', () {
    test('every currency has a capitalised label — no raw data keys', () {
      for (final c in MoneyCurrency.values) {
        expect(c.label, isNotEmpty);
        expect(c.label[0], c.label[0].toUpperCase(),
            reason: '"${c.label}" would print lowercase to a player');
        expect(c.label, isNot(contains('_')));
      }
    });

    test('the data keys the JSON uses all parse', () {
      const seen = <String>[
        'cod', 'plates', 'plate', 'bells', 'bell', 'film', 'films',
        'diamonds', 'diamond', 'buttons', 'button',
      ];
      for (final raw in seen) {
        expect(parseMoneyCurrency(raw), isNotNull, reason: 'cannot parse "$raw"');
      }
    });

    test('a non-currency payout kind returns null instead of throwing', () {
      // booth_owners.json pays out `rating`, which is a star rating, not money.
      expect(parseMoneyCurrency('rating'), isNull);
      expect(parseMoneyCurrency(null), isNull);
      expect(parseMoneyCurrency(''), isNull);
    });

    test('parsing is case and whitespace tolerant', () {
      expect(parseMoneyCurrency(' Cod '), MoneyCurrency.cod);
      expect(parseMoneyCurrency('PLATES'), MoneyCurrency.plates);
    });
  });

  group('published ceilings are quoted, not guessed', () {
    test('the constants match the sources cited in the economy report', () {
      expect(EconomyConstants.buffetAdBonusFraction, 0.40);
      expect(EconomyConstants.buffetAdBonusCapCod, 1000000);
      expect(EconomyConstants.buffetFriendBonusFractionEach, 0.10);
      expect(EconomyConstants.buffetFriendBonusHours, 4);
      expect(EconomyConstants.tipJarAdMultiplier, 2.0);
      expect(EconomyConstants.terraceGathersPerDay, 6);
      expect(EconomyConstants.terraceGatherCooldownMinutes,
          <int>[3, 10, 15, 40, 80, 120]);
      expect(EconomyConstants.takeoutMaxOrdersPerDay, 65);
      expect(EconomyConstants.gachaponMaxDrawsPerDay, 286);
      expect(EconomyConstants.boothPayoutIntervalMinutes, 5);
      expect(EconomyConstants.rareFishDiamondChance, 0.50);
      expect(EconomyConstants.rareFishDiamondAmount, 5);
      expect(EconomyConstants.ticketBoothCapCod, 10000000);
      expect(EconomyConstants.ticketBoothCapFilm, 100000);
    });

    test('the six terrace cooldowns add up to the 4.5 hours the report quotes',
        () {
      final total = EconomyConstants.terraceGatherCooldownMinutes
          .fold<int>(0, (a, b) => a + b);
      expect(total, 268);
      expect(EconomyConstants.terraceGatherCooldownMinutes.length,
          EconomyConstants.terraceGathersPerDay);
    });
  });
}
