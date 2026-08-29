import 'dart:math' as math;

import '../data/income_repository.dart';
import '../model/currency.dart' show MoneyCurrency;
import '../model/economy_constants.dart';
import '../model/income.dart';
import '../model/money_bag.dart';

/// Everything a set of owned facilities contributes, one field per channel.
///
/// Nothing here mixes currencies and nothing here mixes units: `tipPerMinute`
/// is cod per minute, `buffetCodPerHour` is cod per hour, `codPerGather` is a
/// range of cod paid once per Courtyard gather. The old calculator collapsed
/// several of these into a single "minimum earnings" bag, which is how a
/// per-hour buffet figure ended up being multiplied as if it were per minute.
class IncomeSummary {
  const IncomeSummary({
    required this.facilitiesCounted,
    required this.tipCapCod,
    required this.tipPerMinuteCod,
    required this.buffetCodPerHour,
    required this.buffetPlatesPerDay,
    required this.activeCodPerHour,
    required this.codPerPurchase,
    required this.codPerFlowerView,
    required this.terracePayFlatCod,
    required this.terracePayPercent,
    required this.codPerGather,
    required this.filmPerGather,
    required this.bestPetPlayCod,
    required this.bestPetPlayFilm,
    required this.petPlayFacilityCount,
    required this.bestFilmPerPassedGame,
    required this.bestFilmPerExcellentGame,
    required this.takeoutOrders,
    required this.takeoutCapacity,
    required this.counterCapacity,
    required this.cookingEfficiencyPercent,
    required this.concertDailyInvites,
    required this.performerChancePercent,
    required this.gachaDraws,
    required this.gachaMaxLevel,
    required this.wishingWellWishes,
    required this.wishingWellMaxLevel,
    required this.flowerViews,
    required this.bottlesPerDay,
    required this.tableRefreshes,
    required this.bandProfitPercent,
  });

  /// How many of the supplied facilities had at least one verified effect.
  final int facilitiesCounted;

  /// cod — total tip jar capacity.
  final double tipCapCod;

  /// cod per minute into the tip jar.
  final double tipPerMinuteCod;

  /// cod per hour from the Buffet.
  final double buffetCodPerHour;

  /// plates dropped per day.
  final double buffetPlatesPerDay;

  /// cod per hour from the "every N seconds" facilities, which only produce
  /// while the game is open.
  final double activeCodPerHour;

  /// cod added to every restaurant purchase.
  final double codPerPurchase;

  /// cod per terrace flower view.
  final double codPerFlowerView;

  /// cod added to each terrace customer's payment.
  final double terracePayFlatCod;

  /// percent added to each terrace customer's payment.
  final double terracePayPercent;

  /// cod paid by one Courtyard gather.
  final AmountRange codPerGather;

  /// film paid by one Courtyard gather.
  final AmountRange filmPerGather;

  /// Best single pet-play payout owned. Not summed: whether several Pet
  /// Paradise apparatus stack is not documented anywhere.
  final AmountRange bestPetPlayCod;
  final AmountRange bestPetPlayFilm;
  final int petPlayFacilityCount;

  /// Best Game Machine film reward owned, same caveat as pet play.
  final double bestFilmPerPassedGame;
  final double bestFilmPerExcellentGame;

  /// Extra takeout orders per day contributed by Provision Tables.
  final double takeoutOrders;

  /// Extra takeout goods capacity.
  final double takeoutCapacity;

  /// Extra Vegetable Garden counter capacity.
  final double counterCapacity;

  /// Sum of the stove "+N% efficiency" figures printed on the wiki.
  final double cookingEfficiencyPercent;

  /// Free concert invites per day from Lights, before the published ceiling.
  final double concertDailyInvites;

  /// Percent added to the chance of inviting a performer.
  final double performerChancePercent;

  /// Extra Gachapon draws per day.
  final double gachaDraws;

  /// Highest Gachapon level owned.
  final int gachaMaxLevel;

  /// Extra Wishing Well wishes per day.
  final double wishingWellWishes;

  /// Highest Wishing Well level owned.
  final int wishingWellMaxLevel;

  /// Extra flower views from Garden Tables.
  final double flowerViews;

  /// Free terrace bottles per day.
  final double bottlesPerDay;

  /// Free daily refreshes of the terrace table.
  final double tableRefreshes;

  /// Percent added to each named band's earnings, from Concert decor.
  final Map<String, double> bandProfitPercent;

  bool get isEmpty => facilitiesCounted == 0;
}

/// Turns owned facility ids into per-channel totals, and projects those
/// totals forward over time.
class EarningsCalculator {
  const EarningsCalculator._();

  /// Sums the verified income effects of [facilityIds].
  ///
  /// The summing model comes straight from the game's own FAQ (mirrored on
  /// the wiki, "About Facilities"): *"Except for Flowerbed, a facility's
  /// effect (e.g. tips increase, tips cap, star rating, etc.) is calculated
  /// based on the combined effect of unlocked Facilities of different
  /// levels."* So owning a facility is what counts — not displaying it — and
  /// two tip desks really do add their caps together.
  ///
  /// [facilityIds] may contain duplicates or ids with no income; both are
  /// handled (duplicates are counted once).
  static IncomeSummary summarize({
    required Iterable<String> facilityIds,
    required IncomeRepository repository,
  }) {
    var counted = 0;
    var tipCap = 0.0;
    var tipPerMinute = 0.0;
    var buffetPerHour = 0.0;
    var platesPerDay = 0.0;
    var activePerHour = 0.0;
    var perPurchase = 0.0;
    var perFlowerView = 0.0;
    var terraceFlat = 0.0;
    var terracePercent = 0.0;
    var gatherCod = AmountRange.zero;
    var gatherFilm = AmountRange.zero;
    var bestPetCod = AmountRange.zero;
    var bestPetFilm = AmountRange.zero;
    var petCount = 0;
    var bestPassedGame = 0.0;
    var bestExcellentGame = 0.0;
    var orders = 0.0;
    var capacity = 0.0;
    var counter = 0.0;
    var cooking = 0.0;
    var invites = 0.0;
    var performerChance = 0.0;
    var draws = 0.0;
    var gachaLevel = 0;
    var wishes = 0.0;
    var wellLevel = 0;
    var views = 0.0;
    var bottles = 0.0;
    var refreshes = 0.0;
    final bands = <String, double>{};

    final seen = <String>{};
    for (final id in facilityIds) {
      if (!seen.add(id)) continue;
      final entries = repository.forFacility(id);
      if (entries.isEmpty) continue;
      counted++;

      for (final e in entries) {
        switch (e.channel) {
          case IncomeChannel.tipCap:
            tipCap += e.amount ?? 0;
            break;
          case IncomeChannel.tipPerMinute:
            tipPerMinute += e.amount ?? 0;
            break;
          case IncomeChannel.buffetCodPerHour:
            buffetPerHour += e.amount ?? 0;
            break;
          case IncomeChannel.buffetPlatesPerDay:
            platesPerDay += e.amount ?? 0;
            break;
          case IncomeChannel.codPerSeconds:
            // "+240/30s" -> 240 * (3600 / 30) = 28,800 cod per hour of play.
            final seconds = e.seconds ?? 0;
            if (seconds > 0) {
              activePerHour += (e.amount ?? 0) * (3600.0 / seconds);
            }
            break;
          case IncomeChannel.codPerPurchase:
            perPurchase += e.amount ?? 0;
            break;
          case IncomeChannel.codPerFlowerView:
            perFlowerView += e.amount ?? 0;
            break;
          case IncomeChannel.terracePayFlat:
            terraceFlat += e.amount ?? 0;
            break;
          case IncomeChannel.terracePayPercent:
            terracePercent += e.percent ?? 0;
            break;
          case IncomeChannel.codPerGather:
            gatherCod = gatherCod + e.range;
            break;
          case IncomeChannel.filmPerGather:
            gatherFilm = gatherFilm + e.range;
            break;
          case IncomeChannel.petPlayCod:
            petCount++;
            if (e.maxAmount > bestPetCod.max) bestPetCod = e.range;
            break;
          case IncomeChannel.petPlayFilm:
            petCount++;
            if (e.maxAmount > bestPetFilm.max) bestPetFilm = e.range;
            break;
          case IncomeChannel.filmPerPassedGame:
            bestPassedGame = math.max(bestPassedGame, e.amount ?? 0);
            break;
          case IncomeChannel.filmPerExcellentGame:
            bestExcellentGame = math.max(bestExcellentGame, e.amount ?? 0);
            break;
          case IncomeChannel.takeoutOrders:
            orders += e.amount ?? 0;
            break;
          case IncomeChannel.takeoutCapacity:
            capacity += e.amount ?? 0;
            break;
          case IncomeChannel.counterCapacity:
            counter += e.amount ?? 0;
            break;
          case IncomeChannel.cookingEfficiencyPercent:
            cooking += e.amount ?? e.percent ?? 0;
            break;
          case IncomeChannel.concertDailyInvites:
            invites += e.amount ?? 0;
            break;
          case IncomeChannel.performerChancePercent:
            performerChance += e.amount ?? e.percent ?? 0;
            break;
          case IncomeChannel.gachaDraws:
            draws += e.amount ?? 0;
            break;
          case IncomeChannel.gachaLevel:
            gachaLevel = math.max(gachaLevel, (e.amount ?? 0).round());
            break;
          case IncomeChannel.wishingWellWishes:
            wishes += e.amount ?? 0;
            break;
          case IncomeChannel.wishingWellLevel:
            wellLevel = math.max(wellLevel, (e.amount ?? 0).round());
            break;
          case IncomeChannel.wishingWellReward:
            // Reward slots, not currency; nothing to total for the Bank page.
            break;
          case IncomeChannel.flowerViews:
            views += e.amount ?? 0;
            break;
          case IncomeChannel.bottlesPerDay:
            bottles += e.amount ?? 0;
            break;
          case IncomeChannel.tableRefreshes:
            refreshes += e.amount ?? 0;
            break;
          case IncomeChannel.waterXp:
            // Watering XP is not currency.
            break;
          case IncomeChannel.freeRevivePercent:
            // Affects the Game Machine mini-game, not a payout.
            break;
          case IncomeChannel.bandProfitPercent:
            final band = e.band;
            if (band != null && band.isNotEmpty) {
              bands[band] = (bands[band] ?? 0) + (e.percent ?? 0);
            }
            break;
        }
      }
    }

    return IncomeSummary(
      facilitiesCounted: counted,
      tipCapCod: tipCap,
      tipPerMinuteCod: tipPerMinute,
      buffetCodPerHour: buffetPerHour,
      buffetPlatesPerDay: platesPerDay,
      activeCodPerHour: activePerHour,
      codPerPurchase: perPurchase,
      codPerFlowerView: perFlowerView,
      terracePayFlatCod: terraceFlat,
      terracePayPercent: terracePercent,
      codPerGather: gatherCod,
      filmPerGather: gatherFilm,
      bestPetPlayCod: bestPetCod,
      bestPetPlayFilm: bestPetFilm,
      petPlayFacilityCount: petCount,
      bestFilmPerPassedGame: bestPassedGame,
      bestFilmPerExcellentGame: bestExcellentGame,
      takeoutOrders: orders,
      takeoutCapacity: capacity,
      counterCapacity: counter,
      cookingEfficiencyPercent: cooking,
      concertDailyInvites: invites,
      performerChancePercent: performerChance,
      gachaDraws: draws,
      gachaMaxLevel: gachaLevel,
      wishingWellWishes: wishes,
      wishingWellMaxLevel: wellLevel,
      flowerViews: views,
      bottlesPerDay: bottles,
      tableRefreshes: refreshes,
      bandProfitPercent: Map<String, double>.unmodifiable(bands),
    );
  }

  /// Cod sitting in the tip jar after [minutes], never above the jar's cap.
  ///
  /// The jar fills at a fixed rate whether or not the game is open and simply
  /// stops when full; there is no separate time limit on it. (The 12 hour
  /// limit belongs to the Buffet conveyor, and the previous Bank page applied
  /// it to tips as well, which under-reported long absences for anyone whose
  /// jar had not filled by hour 12.)
  ///
  /// Worked example — a jar with 10,000 capacity filling at 5 cod/min:
  /// after 60 minutes it holds min(5 * 60, 10,000) = 300 cod; after 3,000
  /// minutes it holds min(15,000, 10,000) = 10,000 cod, and stays there.
  static double tipsAfterMinutes({
    required double perMinute,
    required double capacity,
    required double minutes,
  }) {
    if (perMinute <= 0 || minutes <= 0) return 0;
    final accrued = perMinute * minutes;
    if (capacity <= 0) return accrued;
    return math.min(accrued, capacity);
  }

  /// Minutes to fill the jar, or null when it never fills at this rate.
  static double? minutesToFillTipJar({
    required double perMinute,
    required double capacity,
  }) {
    if (perMinute <= 0 || capacity <= 0) return null;
    return capacity / perMinute;
  }

  /// Cod the Buffet has banked after [hours], capped at 12 hours of accrual.
  ///
  /// [friendsWorking] applies the +10%-per-friend-for-4-hours bonus from the
  /// Buffet's part-time work feature; pass 0 when nobody is working.
  ///
  /// Worked example — 728,780 cod/h with no friends: after 3 hours the buffet
  /// holds 2,186,340 cod; after 20 hours it still holds 12 * 728,780 =
  /// 8,745,360, because accrual stops at 12 hours.
  static double buffetAfterHours({
    required double perHour,
    required double hours,
    int friendsWorking = 0,
  }) {
    if (perHour <= 0 || hours <= 0) return 0;
    final capped = math.min(
      hours,
      EconomyConstants.buffetMaxAccrualHours.toDouble(),
    );
    final boostedHours = math.min(
      capped,
      EconomyConstants.buffetFriendBonusHours.toDouble(),
    );
    final bonusRate =
        perHour * EconomyConstants.buffetFriendBonusFractionEach * friendsWorking;
    return perHour * capped + bonusRate * boostedHours;
  }

  /// Extra cod the buffet ad grants on top of [base].
  ///
  /// 40% of the banked amount, capped at 1,000,000 cod (wiki Guide:Cod).
  ///
  /// Worked example — 2,000,000 banked: 0.40 * 2,000,000 = 800,000, under the
  /// cap, so the ad is worth 800,000. At 3,000,000 banked the raw bonus is
  /// 1,200,000, which the cap trims to 1,000,000; past 2,500,000 banked the
  /// ad stops getting better.
  static double buffetAdBonus(double base) {
    if (base <= 0) return 0;
    final raw = base * EconomyConstants.buffetAdBonusFraction;
    return math.min(raw, EconomyConstants.buffetAdBonusCapCod.toDouble());
  }

  /// Buffet income where the ad is worth the most it can ever be worth.
  static double buffetAdBreakEvenCod() =>
      EconomyConstants.buffetAdBonusCapCod /
      EconomyConstants.buffetAdBonusFraction;

  /// Expected value of one payout that pays [outcomes] with the given
  /// probabilities, per currency.
  ///
  /// Returns null when the probabilities are not all known — an unknown split
  /// has no expected value, and inventing one would be worse than showing the
  /// min and max.
  static MoneyBag? expectedValue(List<ChanceOutcome> outcomes) {
    if (outcomes.isEmpty) return null;
    var total = 0.0;
    for (final o in outcomes) {
      final chance = o.chance;
      if (chance == null) return null;
      total += chance;
    }
    // Probabilities that do not sum to 1 mean the table is incomplete.
    if ((total - 1.0).abs() > 0.01) return null;

    final bag = MoneyBag();
    for (final o in outcomes) {
      final currency = o.currency;
      if (currency == null) continue; // e.g. a star-rating payout
      bag.add(currency, o.amount * o.chance!);
    }
    return bag;
  }
}

/// One outcome of a random payout: an amount of a currency, with the
/// probability of getting it if that probability is known.
class ChanceOutcome {
  const ChanceOutcome({
    required this.currency,
    required this.amount,
    required this.chance,
  });

  /// Null when the payout is not money at all (booth owners can pay out star
  /// rating instead of a currency).
  final MoneyCurrency? currency;
  final double amount;

  /// Null when the game does not publish the probability.
  final double? chance;
}
