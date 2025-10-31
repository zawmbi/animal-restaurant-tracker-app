
import 'dart:math';
import 'package:collection/collection.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../shared/data/unlocked_store.dart';

class IntRange {
  final int min;
  final int max;
  const IntRange(this.min, this.max);
}

class BankStats {
  final int buffetPerHourCurrent; // only checked/unlocked recipes
  final int buffetPerHourAll;     // potential if all buffet were checked
  final int? tipJarPerHour;       // null if unknown/not purchased
  final IntRange? terraceRange;   // null if unknown
  final IntRange? courtyardRange; // null if unknown

  const BankStats({
    required this.buffetPerHourCurrent,
    required this.buffetPerHourAll,
    this.tipJarPerHour,
    this.terraceRange,
    this.courtyardRange,
  });

  int get totalLow => buffetPerHourCurrent
      + (tipJarPerHour ?? 0)
      + (terraceRange?.min ?? 0)
      + (courtyardRange?.min ?? 0);

  int get totalHigh => buffetPerHourCurrent
      + (tipJarPerHour ?? 0)
      + (terraceRange?.max ?? 0)
      + (courtyardRange?.max ?? 0);
}

/// Fallback config until facilities/customer-driven numbers are wired in.
/// Tweak here, or replace by reading real values from FacilitiesRepository.
class BankConfig {
  /// If Tip Jar facility is purchased, assume this passive rate.
  /// Set to null if there is no passive rate.
  static const int? tipJarPerHourWhenOwned = 2000;

  /// Base ranges for Terrace/Courtyard (cod/h). Replace with real formulas later.
  static const IntRange terraceBase = IntRange(1000, 2500);
  static const IntRange courtyardBase = IntRange(1500, 3200);

  /// Facility ids in your data (used with UnlockedStore bucket 'facility_purchased').
  static const String tipJarFacilityId = 'tip_jar';
  static const String terraceFacilityId = 'terrace';
  static const String courtyardFacilityId = 'courtyard';
}

class BankService {
  final DishesRepository _dishes = DishesRepository.instance;
  final UnlockedStore _store = UnlockedStore.instance;

  Future<BankStats> compute() async {
    final allDishes = await _dishes.all();

    // Buffet: sum +X/h across recipes
    final buffetDishes = allDishes.where((d) => _inAnySection(d, const ['Buffet'])).toList();

    int parsePerHour(String? s) {
      if (s == null || s.isEmpty) return 0;
      final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits) ?? 0;
    }

    final buffetAll = buffetDishes
        .map((d) => parsePerHour(d.earningsPerHour))
        .sum;

    final buffetCurrent = buffetDishes
        .where((d) => _store.isUnlocked('dish', d.id))
        .map((d) => parsePerHour(d.earningsPerHour))
        .sum;

    // Tip jar: only if facility purchased
    int? tipJarPerHour;
    if (_store.isUnlocked('facility_purchased', BankConfig.tipJarFacilityId)) {
      tipJarPerHour = BankConfig.tipJarPerHourWhenOwned; // replace with real value when available
    }

    // Terrace & Courtyard: show base ranges only if facility purchased
    IntRange? terrace;
    if (_store.isUnlocked('facility_purchased', BankConfig.terraceFacilityId)) {
      terrace = BankConfig.terraceBase;
    }

    IntRange? courtyard;
    if (_store.isUnlocked('facility_purchased', BankConfig.courtyardFacilityId)) {
      courtyard = BankConfig.courtyardBase;
    }

    return BankStats(
      buffetPerHourCurrent: buffetCurrent,
      buffetPerHourAll: buffetAll,
      tipJarPerHour: tipJarPerHour,
      terraceRange: terrace,
      courtyardRange: courtyard,
    );
  }

  bool _inAnySection(Dish d, List<String> names) {
    final have = d.sections.map((s) => s.trim().toLowerCase()).toSet();
    for (final n in names) {
      if (have.contains(n.trim().toLowerCase())) return true;
    }
    return false;
  }
}