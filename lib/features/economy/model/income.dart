import '../../facilities/model/facility.dart' show MoneyCurrency;
import 'currency.dart' show parseMoneyCurrency;
import 'money_bag.dart' show AmountRange;

/// One kind of income (or income-shaped effect) a facility can provide.
///
/// These mirror the `channel` values in `assets/data/income.json`, which were
/// transcribed from the wiki facility tables *with their units intact*. The
/// unit is the whole point: the same "+4,200" is per hour on a Buffet Ice
/// Cream and per minute on a Restaurant Table, and conflating the two is what
/// made the old Bank page overstate buffet income sixtyfold.
enum IncomeChannel {
  /// cod added to the tip jar's capacity (Restaurant Tip Desk only).
  tipCap,

  /// cod per minute into the tip jar, accruing online and offline until full.
  tipPerMinute,

  /// cod per hour from the Buffet, accrued offline, 12 hours of accrual max.
  buffetCodPerHour,

  /// plates dropped once per day, after the daily reset.
  buffetPlatesPerDay,

  /// cod produced every `seconds` seconds while the game is open.
  codPerSeconds,

  /// cod added to each customer purchase in the restaurant.
  codPerPurchase,

  /// cod earned each time a terrace customer views a flower.
  codPerFlowerView,

  /// cod added to what each terrace customer pays.
  terracePayFlat,

  /// percent added to what each terrace customer pays.
  terracePayPercent,

  /// cod, random in [min, max], per Courtyard gather.
  codPerGather,

  /// film, random in [min, max], per Courtyard gather.
  filmPerGather,

  /// cod granted after playing with a pet.
  petPlayCod,

  /// film granted after playing with a pet.
  petPlayFilm,

  /// film per passed Game Machine round.
  filmPerPassedGame,

  /// film per "excellent" Game Machine round.
  filmPerExcellentGame,

  /// percent chance of a free revive in the Game Machine.
  freeRevivePercent,

  /// extra takeout orders available per day.
  takeoutOrders,

  /// extra takeout goods storage capacity.
  takeoutCapacity,

  /// extra Vegetable Garden counter capacity.
  counterCapacity,

  /// stove cooking efficiency, in percent, exactly as printed on the wiki.
  cookingEfficiencyPercent,

  /// free concert invites per day.
  concertDailyInvites,

  /// percent added to the chance of inviting a performer.
  performerChancePercent,

  /// extra Gachapon draws per day.
  gachaDraws,

  /// Gachapon level unlocked.
  gachaLevel,

  /// extra Wishing Well wishes per day.
  wishingWellWishes,

  /// extra Wishing Well reward slots.
  wishingWellReward,

  /// Wishing Well level unlocked.
  wishingWellLevel,

  /// extra flower views from the Garden Table.
  flowerViews,

  /// free terrace bottles per day.
  bottlesPerDay,

  /// free daily refreshes of the terrace table items.
  tableRefreshes,

  /// watering XP earned watering a friend's plants.
  waterXp,

  /// percent added to the earnings of one named band (Concert decor).
  bandProfitPercent,
}

const Map<String, IncomeChannel> _channelByKey = <String, IncomeChannel>{
  'tipCap': IncomeChannel.tipCap,
  'tipPerMinute': IncomeChannel.tipPerMinute,
  'buffetCodPerHour': IncomeChannel.buffetCodPerHour,
  'buffetPlatesPerDay': IncomeChannel.buffetPlatesPerDay,
  'codPerSeconds': IncomeChannel.codPerSeconds,
  'codPerPurchase': IncomeChannel.codPerPurchase,
  'codPerFlowerView': IncomeChannel.codPerFlowerView,
  'terracePayFlat': IncomeChannel.terracePayFlat,
  'terracePayPercent': IncomeChannel.terracePayPercent,
  'codPerGather': IncomeChannel.codPerGather,
  'filmPerGather': IncomeChannel.filmPerGather,
  'petPlayCod': IncomeChannel.petPlayCod,
  'petPlayFilm': IncomeChannel.petPlayFilm,
  'filmPerPassedGame': IncomeChannel.filmPerPassedGame,
  'filmPerExcellentGame': IncomeChannel.filmPerExcellentGame,
  'freeRevivePercent': IncomeChannel.freeRevivePercent,
  'takeoutOrders': IncomeChannel.takeoutOrders,
  'takeoutCapacity': IncomeChannel.takeoutCapacity,
  'counterCapacity': IncomeChannel.counterCapacity,
  'cookingEfficiencyPercent': IncomeChannel.cookingEfficiencyPercent,
  'concertDailyInvites': IncomeChannel.concertDailyInvites,
  'performerChancePercent': IncomeChannel.performerChancePercent,
  'gachaDraws': IncomeChannel.gachaDraws,
  'gachaLevel': IncomeChannel.gachaLevel,
  'wishingWellWishes': IncomeChannel.wishingWellWishes,
  'wishingWellReward': IncomeChannel.wishingWellReward,
  'wishingWellLevel': IncomeChannel.wishingWellLevel,
  'flowerViews': IncomeChannel.flowerViews,
  'bottlesPerDay': IncomeChannel.bottlesPerDay,
  'tableRefreshes': IncomeChannel.tableRefreshes,
  'waterXp': IncomeChannel.waterXp,
  'bandProfitPercent': IncomeChannel.bandProfitPercent,
};

/// One income effect on one facility.
class IncomeEntry {
  const IncomeEntry({
    required this.channel,
    this.currency,
    this.band,
    this.amount,
    this.min,
    this.max,
    this.percent,
    this.seconds,
  });

  final IncomeChannel channel;

  /// Null for channels that are not money (draw counts, capacities, percents).
  final MoneyCurrency? currency;

  /// Only for [IncomeChannel.bandProfitPercent]: which band is boosted.
  final String? band;

  /// A fixed quantity, when the game does not randomise it.
  final double? amount;

  /// Low end of a randomised quantity.
  final double? min;

  /// High end of a randomised quantity.
  final double? max;

  /// A percentage, for the percent-shaped channels.
  final double? percent;

  /// Period for [IncomeChannel.codPerSeconds]. Every such row on the wiki is
  /// `/30s`, but the period is carried explicitly rather than assumed.
  final int? seconds;

  /// Smallest value this entry can pay.
  double get minAmount => min ?? amount ?? percent ?? 0;

  /// Largest value this entry can pay.
  double get maxAmount => max ?? amount ?? percent ?? 0;

  AmountRange get range => AmountRange(minAmount, maxAmount);

  /// Returns null for a row whose `channel` this build does not know, so a
  /// data file that gains a channel later cannot crash an older app.
  static IncomeEntry? tryFromJson(Map<String, dynamic> j) {
    final channel = _channelByKey[j['channel']?.toString()];
    if (channel == null) return null;

    double? num_(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return IncomeEntry(
      channel: channel,
      currency: parseMoneyCurrency(j['currency']?.toString()),
      band: j['band']?.toString(),
      amount: num_(j['amount']),
      min: num_(j['min']),
      max: num_(j['max']),
      percent: num_(j['percent']),
      seconds: (j['seconds'] as num?)?.toInt(),
    );
  }
}

/// A concert performer's earnings, from `assets/data/performer_income.json`.
class PerformerIncome {
  const PerformerIncome({
    required this.id,
    required this.name,
    required this.band,
    required this.currency,
    required this.amountPerMinute,
    required this.showDurationMinutes,
    required this.callbackRequirementHours,
  });

  final String id;
  final String name;
  final String? band;
  final MoneyCurrency currency;
  final double amountPerMinute;
  final int showDurationMinutes;
  final int? callbackRequirementHours;

  /// One uninterrupted show, before poster and band-decor bonuses.
  ///
  /// Worked example — Cutie White Bunny: 10 film/min for a 30 minute show
  /// pays 10 * 30 = 300 film.
  double get perShow => amountPerMinute * showDurationMinutes;

  static PerformerIncome? tryFromJson(String id, Map<String, dynamic> j) {
    final currency = parseMoneyCurrency(j['currency']?.toString());
    final perMinute = (j['amountPerMinute'] as num?)?.toDouble();
    final duration = (j['showDurationMinutes'] as num?)?.toInt();
    if (currency == null || perMinute == null || duration == null) return null;
    return PerformerIncome(
      id: id,
      name: (j['name'] ?? id).toString(),
      band: j['band']?.toString(),
      currency: currency,
      amountPerMinute: perMinute,
      showDurationMinutes: duration,
      callbackRequirementHours: (j['callbackRequirementHours'] as num?)?.toInt(),
    );
  }
}
