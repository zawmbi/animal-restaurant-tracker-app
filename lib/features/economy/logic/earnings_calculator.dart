import '../model/money_bag.dart';
import '../model/currency.dart';
import '../../facilities/model/facility.dart';

class EarningsCalculator {
  /// Minimum earnings over [hours] from purchased [facilities].
  /// By default, ignores one-time yields (they happen at purchase time).
  static MoneyBag minimumOverHours({
    required List<Facility> facilities,
    required bool Function(String facilityId) isPurchased,
    required int hours,
    bool includeOneTime = false,
  }) {
    final total = MoneyBag();
    final minutes = hours * 60;

    for (final f in facilities) {
      if (!isPurchased(f.id)) continue;
      for (final y in f.yields) {
        if (y.type == 'one_time') {
          if (includeOneTime) total.add(y.currency, y.amount);
          continue;
        }
        if (y.type == 'per_minute') {
          total.add(y.currency, y.amount * minutes);
          continue;
        }
        if (y.type == 'interval_fixed' || y.type == 'interval_range') {
          final iv = y.intervalMinutes ?? 0;
          if (iv <= 0) continue;
          final cycles = (minutes / iv).floor();
          // For minimum, use the lower bound (amount).
          total.add(y.currency, y.amount * cycles);
          continue;
        }
      }
    }
    return total;
  }
}