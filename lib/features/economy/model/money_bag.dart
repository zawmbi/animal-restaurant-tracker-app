import '../../facilities/model/facility.dart';

/// Typed accumulator that keeps every currency separate.
///
/// Cod, plates, bells, film, buttons and diamonds are never interchangeable in
/// Animal Restaurant, so nothing here ever adds two currencies into one
/// number. Totals are doubles because per-minute and expected-value maths
/// produces fractions; round only at the point of display.
class MoneyBag {
  MoneyBag();

  MoneyBag.of(Map<MoneyCurrency, double> totals) {
    totals.forEach(add);
  }

  final Map<MoneyCurrency, double> _totals = <MoneyCurrency, double>{
    for (final c in MoneyCurrency.values) c: 0.0,
  };

  void add(MoneyCurrency c, double amount) {
    _totals[c] = (_totals[c] ?? 0) + amount;
  }

  void addBag(MoneyBag other) {
    for (final c in MoneyCurrency.values) {
      add(c, other._totals[c] ?? 0);
    }
  }

  double get(MoneyCurrency c) => _totals[c] ?? 0;

  /// A read-only view of every currency, including the zeroes.
  Map<MoneyCurrency, double> get totals => Map.unmodifiable(_totals);

  /// Only the currencies that actually carry a value, in enum order.
  List<MoneyCurrency> get nonZeroCurrencies => <MoneyCurrency>[
        for (final c in MoneyCurrency.values)
          if ((_totals[c] ?? 0).abs() > 1e-9) c,
      ];

  bool get isZero => _totals.values.every((v) => v.abs() <= 1e-9);

  /// A new bag with every total multiplied by [factor].
  ///
  /// This replaces an `operator /` that had no return type and an empty body,
  /// so `bag / 2` silently evaluated to `null` instead of dividing anything.
  MoneyBag scaled(double factor) {
    final out = MoneyBag();
    _totals.forEach((c, v) => out.add(c, v * factor));
    return out;
  }

  @override
  String toString() {
    String fmt(MoneyCurrency c) {
      final v = _totals[c] ?? 0;
      if (v.abs() < 0.0001) return '0';
      return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    }

    return <String>[
      for (final c in MoneyCurrency.values) '${c.key}: ${fmt(c)}',
    ].join('  •  ');
  }
}

/// A quantity the game randomises: the smallest and largest it can be, plus
/// the mean of the two.
///
/// Used wherever the wiki prints a range (`{{Cod|+48~2,400}}` per Courtyard
/// gather, for example). Never collapse one of these to a single number in the
/// UI without saying which end you are showing.
class AmountRange {
  const AmountRange(this.min, this.max);

  const AmountRange.exact(double value)
      : min = value,
        max = value;

  final double min;
  final double max;

  /// Midpoint of the range. This is the *arithmetic mean of the endpoints*,
  /// which is the expected value only if the roll is uniform. The game does
  /// not publish its distribution, so label this an estimate in the UI.
  double get mid => (min + max) / 2;

  bool get isExact => (max - min).abs() <= 1e-9;

  bool get isZero => min.abs() <= 1e-9 && max.abs() <= 1e-9;

  AmountRange operator +(AmountRange other) =>
      AmountRange(min + other.min, max + other.max);

  AmountRange scaled(double factor) =>
      AmountRange(min * factor, max * factor);

  static const AmountRange zero = AmountRange(0, 0);
}

/// Per-currency [AmountRange] accumulator, for income the game randomises.
class RangeBag {
  final Map<MoneyCurrency, AmountRange> _totals = <MoneyCurrency, AmountRange>{};

  void add(MoneyCurrency c, AmountRange r) {
    _totals[c] = (_totals[c] ?? AmountRange.zero) + r;
  }

  void addBag(RangeBag other) {
    other._totals.forEach(add);
  }

  AmountRange get(MoneyCurrency c) => _totals[c] ?? AmountRange.zero;

  List<MoneyCurrency> get nonZeroCurrencies => <MoneyCurrency>[
        for (final c in MoneyCurrency.values)
          if (!get(c).isZero) c,
      ];

  bool get isZero => nonZeroCurrencies.isEmpty;

  RangeBag scaled(double factor) {
    final out = RangeBag();
    _totals.forEach((c, r) => out.add(c, r.scaled(factor)));
    return out;
  }
}
