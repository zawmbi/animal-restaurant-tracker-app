import 'package:flutter/foundation.dart';

/// Five payment types seen across AR: Cod, Plates, Bells, Film, Buttons.
enum MoneyCurrency { cod, plates, bells, film, buttons }

extension MoneyCurrencyKey on MoneyCurrency {
  String get key => describeEnum(this);
}

/// Where the facility lives.
enum FacilityArea {
  restaurant,
  kitchen,
  garden,
  buffet,
  takeout,
  terrace,
  courtyard,
  courtyard_concert,
  courtyard_pets,
}

/// What kind of effect a facility gives.
enum FacilityEffectType {
  tipCapIncrease,      // +10,000 tip cap
  incomePerMinute,     // +5 cod / min
  incomePerInterval,   // +X every N minutes
  incomePerEventRange, // 2–19 film per <eventKey> (min used for "minimum" calc)
  ratingBonus,         // +3 (cosmetic; not part of earnings)
}

/// Price line (e.g. 14,000 cod).
class Price {
  final MoneyCurrency currency;
  final int amount;

  Price({required this.currency, required this.amount});

  factory Price.fromJson(Map<String, dynamic> j) => Price(
        currency: MoneyCurrency.values.firstWhere((e) => e.key == j['currency']),
        amount: j['amount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'currency': currency.key,
        'amount': amount,
      };
}

/// Describes one effect the facility provides.
class FacilityEffect {
  final FacilityEffectType type;

  // For income effects.
  final MoneyCurrency? currency;

  /// General numeric value:
  /// - incomePerMinute: amount per minute
  /// - incomePerInterval: amount each interval
  /// - ratingBonus: flat rating points (cosmetic)
  final double? amount;

  /// For incomePerInterval: minutes in one interval.
  final int? intervalMinutes;

  /// For tipCapIncrease.
  final int? capIncrease;

  /// For incomePerEventRange: the minimum per event and optional max (unused in min calc).
  final int? min;
  final int? max;

  /// For incomePerEventRange: name of the event bucket (e.g. "performance").
  final String? eventKey;

  FacilityEffect({
    required this.type,
    this.currency,
    this.amount,
    this.intervalMinutes,
    this.capIncrease,
    this.min,
    this.max,
    this.eventKey,
  });

  factory FacilityEffect.fromJson(Map<String, dynamic> j) {
    final t = FacilityEffectType.values.firstWhere((e) => e.name == j['type']);
    MoneyCurrency? cur;
    if (j['currency'] != null) {
      cur = MoneyCurrency.values.firstWhere((e) => e.key == j['currency']);
    }
    return FacilityEffect(
      type: t,
      currency: cur,
      amount: (j['amount'] is int)
          ? (j['amount'] as int).toDouble()
          : j['amount'] as double?,
      intervalMinutes: j['intervalMinutes'] as int?,
      capIncrease: j['capIncrease'] as int?,
      min: j['min'] as int?,
      max: j['max'] as int?,
      eventKey: j['eventKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (currency != null) 'currency': currency!.key,
        if (amount != null) 'amount': amount,
        if (intervalMinutes != null) 'intervalMinutes': intervalMinutes,
        if (capIncrease != null) 'capIncrease': capIncrease,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (eventKey != null) 'eventKey': eventKey,
      };
}

/// One concrete buyable facility item (e.g. Tip Desk → “Stone Bowl”).
class Facility {
  final String id;
  final String name;
  final FacilityArea area;

  /// Human label for the slot/group (e.g. "Tip Desk", "Table 1").
  final String group;

  final String? description;

  /// Star requirement to buy/unlock (if applicable).
  final int? requirementStars;

  final List<Price> price;

  /// E.g., +5/min tips, tip cap +10,000, 2–19 film per performance…
  final List<FacilityEffect> effects;

  /// Set/series name (e.g., “Log Scenery”).
  final String? series;

  Facility({
    required this.id,
    required this.name,
    required this.area,
    required this.group,
    this.description,
    this.requirementStars,
    required this.price,
    required this.effects,
    this.series,
  });

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'] as String,
        name: j['name'] as String,
        area: FacilityArea.values.firstWhere((e) => e.name == j['area']),
        group: j['group'] as String,
        description: j['description'] as String?,
        requirementStars: j['requirementsStars'] as int?,
        price: (j['price'] as List<dynamic>)
            .map((e) => Price.fromJson(e as Map<String, dynamic>))
            .toList(),
        effects: (j['effects'] as List<dynamic>)
            .map((e) => FacilityEffect.fromJson(e as Map<String, dynamic>))
            .toList(),
        series: j['series'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area.name,
        'group': group,
        if (description != null) 'description': description,
        if (requirementStars != null) 'requirementsStars': requirementStars,
        'price': price.map((e) => e.toJson()).toList(),
        'effects': effects.map((e) => e.toJson()).toList(),
        if (series != null) 'series': series,
      };
}
