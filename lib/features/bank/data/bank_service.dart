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

  /// Cod per hour from ALL checked facilities (any area) that make cod.
  final int codPerHourFacilitiesCurrent;

  /// Cod per hour from ALL facilities (any area) that make cod, ignoring checks.
  final int codPerHourFacilitiesAll;

  /// Plates per day from checked facilities.
  final int platesPerDayCurrent;

  /// Plates per day from all facilities that produce plates, ignoring checks.
  final int platesPerDayAll;

  const BankStats({
    required this.buffetPerHourCurrent,
    required this.buffetPerHourAll,
    required this.codPerHourFacilitiesCurrent,
    required this.codPerHourFacilitiesAll,
    required this.platesPerDayCurrent,
    required this.platesPerDayAll,
  });

  int get totalCodPerHourCurrent => codPerHourFacilitiesCurrent;
  int get totalCodPerHourAll => codPerHourFacilitiesAll;
}

class BankService {
  final FacilitiesRepository _facilities = FacilitiesRepository.instance;
  final UnlockedStore _store = UnlockedStore.instance;

  Future<BankStats> compute() async {
    final allFacilities = await _facilities.all();

    int codPerMinute(Facility f) {
      return f.effects
          .where((e) =>
              e.type == FacilityEffectType.incomePerMinute &&
              e.currency == MoneyCurrency.cod)
          .map((e) => (e.amount ?? 0).round())
          .sum;
    }

    /// Some facilities might express plates as per-minute or per-interval.
    /// We normalize to **per day** (24h).
    int platesPerDay(Facility f) {
      int total = 0;
      for (final e in f.effects) {
        if (e.currency != MoneyCurrency.plates) continue;

        switch (e.type) {
          case FacilityEffectType.incomePerMinute:
            final amt = (e.amount ?? 0).toDouble();
            total += (amt * 60 * 24).round(); // 24h worth
            break;
          case FacilityEffectType.incomePerInterval:
            final mins = e.intervalMinutes ?? 0;
            if (mins > 0) {
              final amt = (e.amount ?? 0).toDouble();
              final intervalsPerDay = 1440 / mins;
              total += (amt * intervalsPerDay).round();
            }
            break;
          default:
            // Other effect types (tip cap, gacha, etc.) don't affect plates/day.
            break;
        }
      }
      return total;
    }

    // ----- COD from all facilities -----

    final facilitiesWithCod =
        allFacilities.where((f) => codPerMinute(f) > 0).toList();

    final allCodPerMinute =
        facilitiesWithCod.map(codPerMinute).sum;
    final currentCodPerMinute = facilitiesWithCod
        .where((f) => _store.isUnlocked('facility', f.id))
        .map(codPerMinute)
        .sum;

    // ----- Buffet cod only (for stacking rules) -----

    final buffetFacilities =
        facilitiesWithCod.where((f) => f.area == FacilityArea.buffet).toList();

    final buffetAllPerMinute =
        buffetFacilities.map(codPerMinute).sum;
    final buffetCurrentPerMinute = buffetFacilities
        .where((f) => _store.isUnlocked('facility', f.id))
        .map(codPerMinute)
        .sum;

    // ----- Plates per day -----

    final facilitiesWithPlates =
        allFacilities.where((f) => platesPerDay(f) > 0).toList();

    final allPlatesPerDay =
        facilitiesWithPlates.map(platesPerDay).sum;
    final currentPlatesPerDay = facilitiesWithPlates
        .where((f) => _store.isUnlocked('facility', f.id))
        .map(platesPerDay)
        .sum;

    return BankStats(
      buffetPerHourCurrent: buffetCurrentPerMinute * 60,
      buffetPerHourAll: buffetAllPerMinute * 60,
      codPerHourFacilitiesCurrent: currentCodPerMinute * 60,
      codPerHourFacilitiesAll: allCodPerMinute * 60,
      platesPerDayCurrent: currentPlatesPerDay,
      platesPerDayAll: allPlatesPerDay,
    );
  }
}
