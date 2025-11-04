import '../../facilities/model/facility.dart';

/// Simple typed accumulator for currency totals.
/// Uses double internally to handle per-minute math cleanly.
class MoneyBag {
  final Map<MoneyCurrency, double> _totals = {
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

  bool get isZero => _totals.values.every((v) => v == 0);

  @override
  String toString() {
    String fmt(MoneyCurrency c) {
      final v = _totals[c] ?? 0;
      if (v.abs() < 0.0001) return '0';
      return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    }

    return [
      'Cod: ${fmt(MoneyCurrency.cod)}',
      'Plates: ${fmt(MoneyCurrency.plates)}',
      'Bells: ${fmt(MoneyCurrency.bells)}',
      'Film: ${fmt(MoneyCurrency.film)}',
      'Buttons: ${fmt(MoneyCurrency.buttons)}',
      'Diamonds: ${fmt(MoneyCurrency.diamonds)}',

    ].join('  •  ');
  }

  operator /(double other) {}
}
