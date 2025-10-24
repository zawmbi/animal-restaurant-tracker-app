import '../../economy/model/currency.dart';

class Price { final Currency currency; final int amount; const Price(this.currency, this.amount);
  factory Price.fromJson(Map<String, dynamic> j) =>
    Price(CurrencyCodec.fromString(j['currency'] as String), j['amount'] as int);
}

class FacilityYield {
  final String type; // one_time | per_minute | interval_fixed | interval_range
  final Currency currency;
  final int amount; // for one_time, per_minute, interval_fixed, and MIN for range
  final int? maxAmount; // only for interval_range
  final int? intervalMinutes; // for interval types
  final bool goesToTips;

  const FacilityYield({
    required this.type,
    required this.currency,
    required this.amount,
    this.maxAmount,
    this.intervalMinutes,
    this.goesToTips = false,
  });

  factory FacilityYield.fromJson(Map<String, dynamic> j) => FacilityYield(
    type: j['type'] as String,
    currency: CurrencyCodec.fromString(j['currency'] as String),
    amount: j['amount'] as int,
    maxAmount: j['maxAmount'] as int?,
    intervalMinutes: j['intervalMinutes'] as int?,
    goesToTips: j['goesToTips'] as bool? ?? false,
  );
}

class Facility {
  final String id;
  final String name;
  final List<Price> prices;
  final List<FacilityYield> yields;

  const Facility({
    required this.id,
    required this.name,
    required this.prices,
    required this.yields,
  });

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
    id: j['id'] as String,
    name: j['name'] as String,
    prices: (j['prices'] as List).map((e) => Price.fromJson(e)).toList(),
    yields: (j['yields'] as List).map((e) => FacilityYield.fromJson(e)).toList(),
  );
}