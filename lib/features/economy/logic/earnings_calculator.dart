import '../../facilities/model/facility.dart';
import '../model/money_bag.dart';

/// Computes minimum earnings over a time window, based on purchased facilities.
/// - incomePerMinute: amount/min * minutes
/// - incomePerInterval: floor(totalMinutes / interval) * amount
/// - incomePerEventRange: (min) * (eventRatePerHour[eventKey] ?? 0) * hours
/// Tip cap increases / rating bonuses are ignored in the money total, but you
/// can read them separately via `sumTipCapIncrease`.
class EarningsCalculator {
  static MoneyBag minimumOverHours({
    required List<Facility> facilities,
    required bool Function(String id) isPurchased,
    required int hours,
    Map<String, double> eventRatePerHour = const {}, // e.g. {'performance': 4}
  }) {
    final bag = MoneyBag();
    final minutes = hours * 60;

    for (final f in facilities) {
      if (!isPurchased(f.id)) continue;

      for (final eff in f.effects) {
        switch (eff.type) {
          case FacilityEffectType.incomePerMinute:
            if (eff.currency != null && eff.amount != null) {
              bag.add(eff.currency!, (eff.amount!) * minutes);
            }
            break;

          case FacilityEffectType.incomePerInterval:
            if (eff.currency != null &&
                eff.amount != null &&
                eff.intervalMinutes != null &&
                eff.intervalMinutes! > 0) {
              final times = (minutes / eff.intervalMinutes!).floor();
              bag.add(eff.currency!, (eff.amount!) * times);
            }
            break;

          case FacilityEffectType.incomePerEventRange:
            if (eff.currency != null && eff.min != null) {
              final rate = eventRatePerHour[eff.eventKey ?? ''] ?? 0.0;
              final events = rate * hours;
              bag.add(eff.currency!, eff.min!.toDouble() * events);
            }
            break;

          // Everything below contributes no currency to the earnings bag.
          // These used to throw UnimplementedError, which crashed the whole
          // calculation as soon as the player owned a gachapon, a stove or a
          // signature store upgrade. Read tip cap via sumTipCapIncrease.
          case FacilityEffectType.tipCapIncrease:
          case FacilityEffectType.ratingBonus:
          case FacilityEffectType.gachaDraws:
          case FacilityEffectType.gachaLevel:
          case FacilityEffectType.cookingEfficiencyBonus:
          case FacilityEffectType.friendLimitIncrease:
          case FacilityEffectType.storageIncrease:
          case FacilityEffectType.ordersIncrease:
            break;
        }
      }
    }

    return bag;
  }

  /// Sum all tip cap increases from purchased facilities.
  static int sumTipCapIncrease({
    required List<Facility> facilities,
    required bool Function(String id) isPurchased,
  }) {
    var total = 0;
    for (final f in facilities) {
      if (!isPurchased(f.id)) continue;
      for (final eff in f.effects) {
        if (eff.type == FacilityEffectType.tipCapIncrease) {
          total += eff.capIncrease ?? 0;
        }
      }
    }
    return total;
  }
}
