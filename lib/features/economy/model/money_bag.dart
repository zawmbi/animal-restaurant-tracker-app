import 'currency.dart';

class MoneyBag {
  final Map<Currency, int> _m = {};

  MoneyBag();
  MoneyBag.from(Map<Currency, int> values) { _m.addAll(values); }

  int operator [](Currency c) => _m[c] ?? 0;
  void add(Currency c, int amount) => _m[c] = this[c] + amount;

  MoneyBag plus(MoneyBag other) {
    final r = MoneyBag.from(_m);
    for (final e in other._m.entries) { r.add(e.key, e.value); }
    return r;
  }

  MoneyBag times(num k) {
    final r = MoneyBag();
    for (final e in _m.entries) { r._m[e.key] = (e.value * k).floor(); }
    return r;
  }

  Map<String, int> toJson() =>
      _m.map((k, v) => MapEntry(k.key, v));

  @override
  String toString() =>
      _m.entries.map((e) => '${e.value} ${e.key.key}').join(', ');
}