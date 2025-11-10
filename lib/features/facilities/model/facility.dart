// ignore_for_file: deprecated_member_use, constant_identifier_names, unnecessary_cast

import 'package:flutter/foundation.dart';

/// Payment types seen across AR.
enum MoneyCurrency { cod, plates, bells, film, buttons, diamonds }

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
  incomePerEventRange, // 2–19 film per <eventKey>
  ratingBonus,         // +3 (cosmetic)
  gachaDraws,          // number of draws unlocked
  gachaLevel,          // level of the gachapon
}

/// ---- helpers: tolerant enum parsing ------------------------------------------------

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final x in items) {
    if (test(x)) return x;
  }
  return null;
}

String _normalizeEnumKey(String? raw) {
  if (raw == null) return '';
  var s = raw.trim().toLowerCase();
  s = s
      .replaceAll('(', ' ')
      .replaceAll(')', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' & ', ' and ')
      .replaceAll('-', ' ')
      .replaceAll('/', ' ')
      .trim()
      .replaceAll(' ', '_');
  return s;
}

FacilityArea _parseArea(Map<String, dynamic> j) {
  final key = _normalizeEnumKey(j['area'] as String?);
  final found = _firstWhereOrNull(
    FacilityArea.values,
    (e) => describeEnum(e) == key,
  );
  if (found != null) return found;

  // fallback for known labels
  if (key == 'courtyard_pets' || key == 'courtyard_pets_') {
    return FacilityArea.courtyard_pets;
  }
  if (key == 'courtyard_concert') {
    return FacilityArea.courtyard_concert;
  }

  throw FormatException(
      'Unknown FacilityArea "$key" for facility ${j['id'] ?? j['name']}');
}

MoneyCurrency _parseCurrency(String raw, Map<String, dynamic> j) {
  var key = _normalizeEnumKey(raw);
  if (key == 'diamond') key = 'diamonds'; // accept singular
  final found = _firstWhereOrNull(
    MoneyCurrency.values,
    (e) => (e as MoneyCurrency).key == key,
  );
  if (found != null) return found as MoneyCurrency;
  throw FormatException(
      'Unknown currency "$raw" for facility ${j['id'] ?? j['name']}');
}

FacilityEffectType _parseEffectType(String raw, Map<String, dynamic> j) {
  final key = _normalizeEnumKey(raw);

  // Compare normalized ↔ normalized so camelCase works
  final found = _firstWhereOrNull(
    FacilityEffectType.values,
    (e) => _normalizeEnumKey(describeEnum(e)) == key,
  );
  if (found != null) return found;

  // Fallback aliases
  switch (key) {
    case 'income_per_minute':
    case 'incomeperminute':
      return FacilityEffectType.incomePerMinute;
    case 'income_per_interval':
    case 'incomeperinterval':
      return FacilityEffectType.incomePerInterval;
    case 'income_per_event_range':
    case 'incomepereventrange':
      return FacilityEffectType.incomePerEventRange;
    case 'tip_cap_increase':
    case 'tipcapincrease':
      return FacilityEffectType.tipCapIncrease;
    case 'rating_bonus':
    case 'ratingbonus':
      return FacilityEffectType.ratingBonus;
    case 'gacha_draws':
    case 'gachadraws':
      return FacilityEffectType.gachaDraws;
    case 'gacha_level':
    case 'gachalevel':
      return FacilityEffectType.gachaLevel;
    default:
      throw FormatException(
          'Unknown effect type "$raw" for facility ${j['id'] ?? j['name']}');
  }
}

/// Price line (e.g. 14,000 cod).
class Price {
  final MoneyCurrency currency;
  final int amount;

  Price({required this.currency, required this.amount});

  factory Price.fromJson(Map<String, dynamic> j, Map<String, dynamic> parent) =>
      Price(
        currency: _parseCurrency(j['currency']?.toString() ?? '', parent),
        amount: (j['amount'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'currency': currency.key,
        'amount': amount,
      };
}

/// Describes one effect the facility provides.
class FacilityEffect {
  final FacilityEffectType type;

  /// Currency for income effects.
  final MoneyCurrency? currency;

  /// General numeric value:
  /// - incomePerMinute: amount per minute
  /// - incomePerInterval: amount each interval
  /// - ratingBonus / gachaDraws: flat amount
  final double? amount;

  /// For incomePerInterval: minutes in one interval.
  final int? intervalMinutes;

  /// For tipCapIncrease.
  final int? capIncrease;

  /// For incomePerEventRange: the minimum per event and optional max.
  final int? min;
  final int? max;

  /// For incomePerEventRange: name of the event bucket (e.g. "performance").
  final String? eventKey;

  /// For gachaLevel: level number
  final int? level;

  FacilityEffect({
    required this.type,
    this.currency,
    this.amount,
    this.intervalMinutes,
    this.capIncrease,
    this.min,
    this.max,
    this.eventKey,
    this.level,
  });

  factory FacilityEffect.fromJson(
      Map<String, dynamic> j, Map<String, dynamic> parent) {
    final t = _parseEffectType(j['type']?.toString() ?? '', parent);

    MoneyCurrency? cur;
    final curRaw = j['currency']?.toString();
    if (curRaw != null && curRaw.isNotEmpty) {
      cur = _parseCurrency(curRaw, parent);
    }

    final amtField = j['amount'];
    final amt = amtField == null
        ? null
        : (amtField is num
            ? amtField.toDouble()
            : double.tryParse(amtField.toString()));

    return FacilityEffect(
      type: t,
      currency: cur,
      amount: amt,
      intervalMinutes: (j['intervalMinutes'] as num?)?.toInt(),
      capIncrease: (j['capIncrease'] as num?)?.toInt(),
      min: (j['min'] as num?)?.toInt(),
      max: (j['max'] as num?)?.toInt(),
      eventKey: j['eventKey'] as String?,
      level: (j['level'] as num?)?.toInt(),
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
        if (level != null) 'level': level,
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
  final int? requirementStars; // JSON key is "requirementsStars"

  final List<Price> price;

  /// E.g., +5/min tips, tip cap +10,000, 2–19 film per performance…
  final List<FacilityEffect> effects;

  /// Set/series name (e.g., “Log Scenery”).
  final String? series;

  /// Event/limited-time/prereq labels (e.g., "Sold During Christmas Event").
  final List<String>? specialRequirements;

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
    this.specialRequirements,
  });

  factory Facility.fromJson(Map<String, dynamic> j) {
    final prices = (j['price'] as List?) ?? const [];
    final effects = (j['effects'] as List?) ?? const [];

    return Facility(
      id: j['id'] as String,
      name: j['name'] as String,
      area: _parseArea(j),
      group: j['group'] as String,
      description: j['description'] as String?,
      requirementStars: (j['requirementsStars'] as num?)?.toInt(),
      price: prices
          .map((e) => Price.fromJson(e as Map<String, dynamic>, j))
          .toList(),
      effects: effects
          .map((e) => FacilityEffect.fromJson(e as Map<String, dynamic>, j))
          .toList(),
      series: j['series'] as String?,
      specialRequirements:
          (j['specialRequirements'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

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
        if (specialRequirements != null && specialRequirements!.isNotEmpty)
          'specialRequirements': specialRequirements,
      };
}
