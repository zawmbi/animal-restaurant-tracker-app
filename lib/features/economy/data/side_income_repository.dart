import '../../shared/json_loader.dart';
import '../logic/earnings_calculator.dart' show ChanceOutcome;
import '../model/currency.dart' show MoneyCurrency, parseMoneyCurrency;

/// A leased fishing-pond booth and what it pays.
class BoothIncome {
  const BoothIncome({
    required this.id,
    required this.outcomes,
    required this.stayMinMinutes,
    required this.stayMaxMinutes,
  });

  final String id;

  /// The mutually exclusive payouts, once every 5 minutes. The wiki writes
  /// these as "Plates +10 **or** Cod +100" and publishes no probabilities, so
  /// `chance` is usually null.
  final List<ChanceOutcome> outcomes;

  final int? stayMinMinutes;
  final int? stayMaxMinutes;

  bool get hasIncome => outcomes.isNotEmpty;

  /// True only when every outcome carries a probability.
  bool get chancesKnown =>
      outcomes.isNotEmpty && outcomes.every((o) => o.chance != null);

  /// Payouts of [currency] this booth can make, largest first is not
  /// guaranteed — callers take the max themselves.
  Iterable<double> amountsOf(MoneyCurrency currency) =>
      outcomes.where((o) => o.currency == currency).map((o) => o.amount);
}

/// A staff member's income-relevant raise levels.
class StaffIncome {
  const StaffIncome({
    required this.id,
    required this.name,
    required this.levels,
  });

  final String id;
  final String name;

  /// One entry per raise level, in level order.
  final List<StaffIncomeLevel> levels;

  StaffIncomeLevel? levelAt(int level) {
    for (final l in levels) {
      if (l.level == level) return l;
    }
    return null;
  }

  int get maxLevel =>
      levels.isEmpty ? 0 : levels.map((l) => l.level).reduce((a, b) => a > b ? a : b);
}

class StaffIncomeLevel {
  const StaffIncomeLevel({
    required this.level,
    this.codPer60Seconds,
    this.tipsPerMinute,
    this.platesPer4Hours,
  });

  final int level;

  /// Eggy: loose cod produced in the Kitchen every 60 seconds.
  final double? codPer60Seconds;

  /// Apricat: cod per minute added to the tip jar while she is sweeping.
  final double? tipsPerMinute;

  /// Yolky: plates earned every 4 hours of part-time work.
  final double? platesPer4Hours;

  bool get hasIncome =>
      codPer60Seconds != null || tipsPerMinute != null || platesPer4Hours != null;
}

/// Loads the income-bearing parts of `booth_owners.json` and `staff.json`.
///
/// These two assets belong to the Customers and Staff features; this
/// repository only reads the numeric payout fields out of them and never
/// writes them back.
class SideIncomeRepository {
  SideIncomeRepository._();

  static final SideIncomeRepository instance = SideIncomeRepository._();

  static const String boothAsset = 'assets/data/booth_owners.json';
  static const String staffAsset = 'assets/data/staff.json';

  Map<String, BoothIncome>? _booths;
  Map<String, StaffIncome>? _staff;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final boothRaw = await JsonLoader.load(boothAsset);
      final booths = <String, BoothIncome>{};
      if (boothRaw is Map) {
        boothRaw.forEach((key, value) {
          if (value is! Map) return;
          final m = Map<String, dynamic>.from(value);
          final outcomes = <ChanceOutcome>[];
          final income = m['incomeEvery5Min'];
          if (income is List) {
            for (final raw in income) {
              if (raw is! Map) continue;
              final e = Map<String, dynamic>.from(raw);
              final amount = (e['amount'] as num?)?.toDouble();
              if (amount == null) continue;
              outcomes.add(ChanceOutcome(
                // A null currency here means a non-money payout (star
                // rating), which is kept so the outcome count stays honest.
                currency: parseMoneyCurrency(e['currency']?.toString()),
                amount: amount,
                chance: (e['chance'] as num?)?.toDouble(),
              ));
            }
          }
          final stay = m['stayDurationMinutes'];
          booths[key.toString()] = BoothIncome(
            id: key.toString(),
            outcomes: outcomes,
            stayMinMinutes:
                stay is Map ? (stay['min'] as num?)?.toInt() : null,
            stayMaxMinutes:
                stay is Map ? (stay['max'] as num?)?.toInt() : null,
          );
        });
      }
      _booths = booths;

      final staffRaw = await JsonLoader.load(staffAsset);
      final staff = <String, StaffIncome>{};
      if (staffRaw is List) {
        for (final raw in staffRaw) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final id = m['id']?.toString();
          if (id == null) continue;
          final levels = <StaffIncomeLevel>[];
          final ups = m['raiseUpgrades'];
          if (ups is List) {
            for (final u in ups) {
              if (u is! Map) continue;
              final lm = Map<String, dynamic>.from(u);
              final level = (lm['level'] as num?)?.toInt();
              if (level == null) continue;
              final l = StaffIncomeLevel(
                level: level,
                codPer60Seconds: (lm['codPer60Seconds'] as num?)?.toDouble(),
                tipsPerMinute: (lm['tipsPerMinute'] as num?)?.toDouble(),
                platesPer4Hours: (lm['platesPer4Hours'] as num?)?.toDouble(),
              );
              if (l.hasIncome) levels.add(l);
            }
          }
          // Sorted explicitly by level: List.sort is not stable in Dart, so
          // "already in file order" is not something to rely on, and the
          // comparator below is a total order on the field we index by.
          levels.sort((a, b) => a.level.compareTo(b.level));
          if (levels.isNotEmpty) {
            staff[id] = StaffIncome(
              id: id,
              name: (m['name'] ?? id).toString(),
              levels: levels,
            );
          }
        }
      }
      _staff = staff;
    } catch (_) {
      _loadFuture = null; // allow a retry
      rethrow;
    }
  }

  Map<String, BoothIncome> get booths =>
      _booths ?? const <String, BoothIncome>{};

  Map<String, StaffIncome> get staff => _staff ?? const <String, StaffIncome>{};

  /// Booths that pay something, in a stable order (id ascending).
  List<BoothIncome> get payingBooths {
    final list = booths.values.where((b) => b.hasIncome).toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }
}
