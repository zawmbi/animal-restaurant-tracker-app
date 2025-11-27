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

  /// Tip Jar cod per hour from checked NON-buffet facilities
  /// (any facility with incomePerMinute cod).
  final int tipJarPerHourCurrent;

  /// Tip Jar cod per hour if all NON-buffet cod facilities were checked.
  final int tipJarPerHourAll;

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
    required this.tipJarPerHourCurrent,
    required this.tipJarPerHourAll,
    required this.onlineCodPerHourCurrent,
    required this.onlineCodPerHourAll,
    required this.platesPerDayCurrent,
    required this.platesPerDayAll,
  });

  int get totalCodPerHourCurrent =>
      buffetPerHourCurrent +
      tipJarPerHourCurrent +
      onlineCodPerHourCurrent;

  int get totalCodPerHourAll =>
      buffetPerHourAll +
      tipJarPerHourAll +
      onlineCodPerHourAll;
}
class BankService {
  final FacilitiesRepository _facilities = FacilitiesRepository.instance;
  final UnlockedStore _store = UnlockedStore.instance;

  Future<BankStats> compute() async {
    final allFacilities = await _facilities.all();

    bool _isUnlocked(Facility f) => _store.isUnlocked('facility', f.id);

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

    // ----- Split buffet vs tip-jar vs online-only cod -----

    // BUFFET: area == buffet, any cod income (per-minute OR interval)
    final buffetFacilities = allFacilities
        .where((f) => f.area == FacilityArea.buffet)
        .toList();

    //  TIP JAR: NON-buffet, per-minute cod only (same as before)
    final nonBuffetCodFacilities = allFacilities
        .where((f) =>
            f.area != FacilityArea.buffet && codPerMinute(f) > 0)
        .toList();

    //  ONLINE-ONLY: NON-buffet, interval-based cod
    final intervalCodFacilities = allFacilities
        .where((f) =>
            f.area != FacilityArea.buffet &&
            codPerHourFromInterval(f) > 0)
        .toList();

    // Buffet per HOUR (now includes interval-based income!)
    int buffetAllPerHour = 0;
    int buffetCurrentPerHour = 0;

    for (final f in buffetFacilities) {
      final perMinute = codPerMinute(f); // might be 0 for your buffet JSON
      final perHourFromMinute = perMinute * 60;
      final perHourFromInterval = codPerHourFromInterval(f);

      final perHourTotal = perHourFromMinute + perHourFromInterval;

      buffetAllPerHour += perHourTotal;
      if (_isUnlocked(f)) {
        buffetCurrentPerHour += perHourTotal;
      }
    }

    // Tip Jar per hour (non-buffet cod-per-minute)
    final tipAllPerMinute =
        nonBuffetCodFacilities.map(codPerMinute).sum;
    final tipCurrentPerMinute = nonBuffetCodFacilities
        .where(_isUnlocked)
        .map(codPerMinute)
        .sum;

    // Online cod per hour from intervals (non-buffet only now)
    final onlineAllPerHour =
        intervalCodFacilities.map(codPerHourFromInterval).sum;
    final onlineCurrentPerHour = intervalCodFacilities
        .where(_isUnlocked)
        .map(codPerHourFromInterval)
        .sum;

    // Plates per day
    final platesAllPerDay =
        allFacilities.map(platesPerDay).where((v) => v > 0).sum;
    final platesCurrentPerDay = allFacilities
        .where(_isUnlocked)
        .map(platesPerDay)
        .where((v) => v > 0)
        .sum;

    return BankStats(
      buffetPerHourCurrent: buffetCurrentPerHour,
      buffetPerHourAll: buffetAllPerHour,
      tipJarPerHourCurrent: tipCurrentPerMinute * 60,
      tipJarPerHourAll: tipAllPerMinute * 60,
      onlineCodPerHourCurrent: onlineCurrentPerHour,
      onlineCodPerHourAll: onlineAllPerHour,
      platesPerDayCurrent: platesCurrentPerDay,
      platesPerDayAll: platesAllPerDay,
    );
  }
}
