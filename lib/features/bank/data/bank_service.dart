// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

import '../../shared/data/unlocked_store.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';

class BankStats {
  /// Buffet cod per hour from checked buffet facilities.
  final int buffetPerHourCurrent;

  /// Buffet cod per hour if all buffet facilities that make cod were checked.
  final int buffetPerHourAll;

  /// Tip jar maximum capacity (sum of tipCapIncrease) from checked facilities.
  final int tipCapCurrent;

  /// Tip jar maximum capacity from all tip desk facilities.
  final int tipCapAll;

  /// Tip jar fill rate: cod per hour from checked restaurant facilities.
  final int tipFillPerHourCurrent;

  /// Tip jar fill rate: cod per hour from all restaurant facilities.
  final int tipFillPerHourAll;

  /// Online-only cod per hour (incomePerInterval cod), checked facilities.
  final int onlineCodPerHourCurrent;

  /// Online-only cod per hour, all facilities.
  final int onlineCodPerHourAll;

  /// Plates per day from checked facilities.
  final int platesPerDayCurrent;

  /// Plates per day from all plate-making facilities.
  final int platesPerDayAll;

  const BankStats({
    required this.buffetPerHourCurrent,
    required this.buffetPerHourAll,
    required this.tipCapCurrent,
    required this.tipCapAll,
    required this.tipFillPerHourCurrent,
    required this.tipFillPerHourAll,
    required this.onlineCodPerHourCurrent,
    required this.onlineCodPerHourAll,
    required this.platesPerDayCurrent,
    required this.platesPerDayAll,
  });
}
class BankService {
  final FacilitiesRepository _facilities = FacilitiesRepository.instance;
  final UnlockedStore _store = UnlockedStore.instance;

  Future<BankStats> compute() async {
    final allFacilities = await _facilities.all();

    bool isUnlocked(Facility f) => _store.isUnlocked('facility', f.id);

    // ----- Helpers -----

    int codPerMinute(Facility f) {
      return f.effects
          .where((e) =>
              e.type == FacilityEffectType.incomePerMinute &&
              e.currency == MoneyCurrency.cod)
          .map((e) => (e.amount ?? 0).round())
          .sum;
    }

    int codPerHourFromInterval(Facility f) {
      int total = 0;
      for (final e in f.effects) {
        if (e.type != FacilityEffectType.incomePerInterval) continue;
        if (e.currency != MoneyCurrency.cod) continue;

        final minutes = e.intervalMinutes ?? 0;
        if (minutes <= 0) continue;
        final amt = (e.amount ?? 0).toDouble();
        final perHour = amt * (60.0 / minutes);
        total += perHour.round();
      }
      return total;
    }

    int platesPerDay(Facility f) {
      int total = 0;
      for (final e in f.effects) {
        if (e.currency != MoneyCurrency.plates) continue;

        switch (e.type) {
          case FacilityEffectType.incomePerMinute:
            final amt = (e.amount ?? 0).toDouble();
            // 24 hours * 60 minutes
            total += (amt * 60 * 24).round();
            break;
          case FacilityEffectType.incomePerInterval:
            final minutes = e.intervalMinutes ?? 0;
            if (minutes <= 0) continue;
            final amt = (e.amount ?? 0).toDouble();
            final intervalsPerDay = 1440.0 / minutes;
            total += (amt * intervalsPerDay).round();
            break;
          default:
            break;
        }
      }
      return total;
    }

    // ----- Tip cap from tipCapIncrease effects -----

    int tipCap(Facility f) {
      return f.effects
          .where((e) => e.type == FacilityEffectType.tipCapIncrease)
          .map((e) => e.capIncrease ?? 0)
          .sum;
    }

    final tipCapFacilities = allFacilities
        .where((f) => tipCap(f) > 0)
        .toList();

    final tipCapAllTotal = tipCapFacilities.map(tipCap).sum;
    final tipCapCurrentTotal =
        tipCapFacilities.where(isUnlocked).map(tipCap).sum;

    // ----- Split buffet vs tip-jar vs online-only cod -----

    // BUFFET: area == buffet, any cod income (per-minute OR interval)
    final buffetFacilities = allFacilities
        .where((f) => f.area == FacilityArea.buffet)
        .toList();

    // TIP JAR FILL RATE: restaurant area, per-minute cod
    final restaurantCodFacilities = allFacilities
        .where((f) =>
            f.area == FacilityArea.restaurant && codPerMinute(f) > 0)
        .toList();

    // ONLINE-ONLY: NON-buffet, interval-based cod
    final intervalCodFacilities = allFacilities
        .where((f) =>
            f.area != FacilityArea.buffet &&
            codPerHourFromInterval(f) > 0)
        .toList();

    // Buffet per HOUR (includes both per-minute and interval-based income)
    int buffetAllPerHour = 0;
    int buffetCurrentPerHour = 0;

    for (final f in buffetFacilities) {
      final perHourFromMinute = codPerMinute(f) * 60;
      final perHourFromInterval = codPerHourFromInterval(f);
      final perHourTotal = perHourFromMinute + perHourFromInterval;

      buffetAllPerHour += perHourTotal;
      if (isUnlocked(f)) {
        buffetCurrentPerHour += perHourTotal;
      }
    }

    // Tip jar fill rate (restaurant area cod-per-minute)
    final tipFillAllPerMinute =
        restaurantCodFacilities.map(codPerMinute).sum;
    final tipFillCurrentPerMinute = restaurantCodFacilities
        .where(isUnlocked)
        .map(codPerMinute)
        .sum;

    // Online cod per hour from intervals (non-buffet only)
    final onlineAllPerHour =
        intervalCodFacilities.map(codPerHourFromInterval).sum;
    final onlineCurrentPerHour = intervalCodFacilities
        .where(isUnlocked)
        .map(codPerHourFromInterval)
        .sum;

    // Plates per day
    final platesAllPerDay =
        allFacilities.map(platesPerDay).where((v) => v > 0).sum;
    final platesCurrentPerDay = allFacilities
        .where(isUnlocked)
        .map(platesPerDay)
        .where((v) => v > 0)
        .sum;

    return BankStats(
      buffetPerHourCurrent: buffetCurrentPerHour,
      buffetPerHourAll: buffetAllPerHour,
      tipCapCurrent: tipCapCurrentTotal,
      tipCapAll: tipCapAllTotal,
      tipFillPerHourCurrent: tipFillAllPerMinute > 0
          ? tipFillCurrentPerMinute * 60
          : 0,
      tipFillPerHourAll: tipFillAllPerMinute * 60,
      onlineCodPerHourCurrent: onlineCurrentPerHour,
      onlineCodPerHourAll: onlineAllPerHour,
      platesPerDayCurrent: platesCurrentPerDay,
      platesPerDayAll: platesAllPerDay,
    );
  }
}
