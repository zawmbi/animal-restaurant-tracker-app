/// The terrace "customers pay" bonuses, and what one more facility adds to them.
///
/// Three terrace groups carry a pay bonus — Gathering Table, Table 1 and
/// Table 2 — 89 facilities between them. Each gives either a flat cod amount
/// added to what a terrace customer pays, or a percentage added to it; no
/// facility gives both. Per the game's FAQ, every *unlocked* facility's effect
/// applies whether or not it is the one currently on display, so these sum
/// rather than replacing one another.
///
/// The rest of the terrace — Display Stand, Open Air Cinema, Telescope, Snack
/// Counter and so on — pays through other channels and is deliberately not
/// counted here. This is the "what will a customer hand me" number only.
library;

import '../../facilities/model/facility.dart';
import '../data/income_repository.dart';
import '../model/income.dart';

/// Groups whose facilities carry a `terracePayFlat` or `terracePayPercent`
/// effect. Derived from the data, not hardcoded knowledge: every facility in
/// these three groups that has income data has a pay channel, and no facility
/// outside them does.
const Set<String> kTerracePayGroups = <String>{
  'Gathering Table',
  'Table 1',
  'Table 2',
};

/// What one facility contributes to terrace customer payments.
class TerracePayEffect {
  const TerracePayEffect({this.flatCod = 0, this.percent = 0});

  /// cod added to each terrace customer's payment.
  final double flatCod;

  /// Percentage points added to each terrace customer's payment.
  final double percent;

  bool get isEmpty => flatCod == 0 && percent == 0;

  /// Reads the pay channels out of a facility's income entries, ignoring
  /// every other channel.
  static TerracePayEffect fromEntries(List<IncomeEntry> entries) {
    double flat = 0;
    double percent = 0;
    for (final e in entries) {
      switch (e.channel) {
        case IncomeChannel.terracePayFlat:
          flat += e.amount ?? 0;
        case IncomeChannel.terracePayPercent:
          percent += e.percent ?? e.amount ?? 0;
        default:
          break;
      }
    }
    return TerracePayEffect(flatCod: flat, percent: percent);
  }
}

/// A facility's pay effect set against everything already unlocked.
class TerracePayProjection {
  const TerracePayProjection({
    required this.ownedFlatCod,
    required this.ownedPercent,
    required this.ownedCount,
    required this.totalCount,
    required this.effect,
    required this.alreadyUnlocked,
  });

  /// Σ of the flat bonuses on every unlocked pay facility, this one included
  /// when it is already unlocked.
  final double ownedFlatCod;

  /// Σ of the percentage bonuses on every unlocked pay facility, same rule.
  final double ownedPercent;

  /// How many of the pay facilities are unlocked, and how many exist.
  final int ownedCount;
  final int totalCount;

  /// What the facility being looked at contributes.
  final TerracePayEffect effect;

  /// Whether it is already ticked off, in which case it is counted in the
  /// owned totals and adds nothing further.
  final bool alreadyUnlocked;

  /// The flat bonus this facility would add. Zero when already unlocked.
  double get addedFlatCod => alreadyUnlocked ? 0 : effect.flatCod;

  /// The percentage points this facility would add. Zero when already unlocked.
  double get addedPercent => alreadyUnlocked ? 0 : effect.percent;

  double get afterFlatCod => ownedFlatCod + addedFlatCod;
  double get afterPercent => ownedPercent + addedPercent;

  /// The fraction by which this facility raises your terrace takings, counting
  /// the percentage channel alone. Null when it has no percentage bonus.
  ///
  /// This one number is exact, and that is worth spelling out. If a customer
  /// currently pays `base * (1 + owned/100)` and would afterwards pay
  /// `base * (1 + after/100)`, then `base` — the figure the game never
  /// publishes and the reason the Bank page refuses to quote terrace cod —
  /// cancels out of the ratio entirely. So the *relative* gain is knowable
  /// even though the absolute one is not.
  ///
  /// The +5% on a table you buy at +150% is not a 5% raise; it is
  /// 2.55/2.50 - 1, i.e. 2%. That gap is the whole reason this is worth
  /// showing on the page rather than leaving the reader to add percentages in
  /// their head.
  ///
  /// Assumes the percentages add rather than compound. The wiki wording
  /// implies addition and the Bank page has always assumed it; nothing in the
  /// game states it. See docs/economy-report.md §7.
  double? get percentUpliftFraction {
    if (addedPercent <= 0) return null;
    final before = 100 + ownedPercent;
    if (before <= 0) return null;
    return (100 + afterPercent) / before - 1;
  }

  /// The uplift applied to an observed per-gather figure, giving the extra cod
  /// a gather would bring. Null when there is no percentage bonus or no
  /// observation to apply it to.
  ///
  /// Only the percentage channel can be converted this way. A flat bonus is
  /// "per customer", and how many customers a gather brings is not published
  /// for the terrace, so multiplying it out would be inventing a number.
  double? extraCodPerGather(double observedCodPerGather) {
    if (observedCodPerGather <= 0) return null;
    final uplift = percentUpliftFraction;
    if (uplift == null) return null;
    return observedCodPerGather * uplift;
  }

  /// True when there is anything worth drawing a card for.
  bool get hasAnything => effect.isEmpty == false || ownedCount > 0;
}

/// Builds the projection for [facility] against the player's unlocked set.
///
/// [terraceFacilities] is every facility in the terrace area; [unlockedIds] is
/// the unlocked set for the bucket terrace facilities live in. Both are passed
/// in rather than fetched so this stays a pure function and stays testable.
TerracePayProjection buildTerracePayProjection({
  required Facility facility,
  required Iterable<Facility> terraceFacilities,
  required Set<String> unlockedIds,
  required IncomeRepository income,
}) {
  double flat = 0;
  double percent = 0;
  int owned = 0;
  int total = 0;

  for (final f in terraceFacilities) {
    if (!kTerracePayGroups.contains(f.group)) continue;
    final effect = TerracePayEffect.fromEntries(income.forFacility(f.id));
    if (effect.isEmpty) continue;
    total++;
    if (!unlockedIds.contains(f.id)) continue;
    owned++;
    flat += effect.flatCod;
    percent += effect.percent;
  }

  return TerracePayProjection(
    ownedFlatCod: flat,
    ownedPercent: percent,
    ownedCount: owned,
    totalCount: total,
    effect: TerracePayEffect.fromEntries(income.forFacility(facility.id)),
    alreadyUnlocked: unlockedIds.contains(facility.id),
  );
}
