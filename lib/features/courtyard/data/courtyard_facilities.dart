import 'package:equatable/equatable.dart';

/// Price entry from JSON:
/// {
///   "currency": "cod" | "film" | "diamond",
///   "amount": 1000
/// }
class CourtyardPrice extends Equatable {
  final String currency; // "cod", "film", or "diamond"
  final int amount;

  const CourtyardPrice({
    required this.currency,
    required this.amount,
  });

  factory CourtyardPrice.fromJson(Map<String, dynamic> json) {
    return CourtyardPrice(
      currency: json['currency'] as String,
      amount: (json['amount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'amount': amount,
      };

  @override
  List<Object?> get props => [currency, amount];
}

/// Effect entry from JSON.
/// Examples from your other facilities:
///   { "type": "incomePerMinute", "currency": "cod", "amount": 5 }
///   { "type": "ratingBonus", "amount": 3 }
/// Courtyard can also use:
///   { "type": "friendLimitIncrease", "friendSlots": 5 }
class CourtyardEffect extends Equatable {
  final String type; // e.g. incomePerMinute, ratingBonus, friendLimitIncrease
  final String? currency; // e.g. cod, film
  final num? amount;
  final int? capIncrease;
  final int? friendSlots;

  const CourtyardEffect({
    required this.type,
    this.currency,
    this.amount,
    this.capIncrease,
    this.friendSlots,
  });

  factory CourtyardEffect.fromJson(Map<String, dynamic> json) {
    return CourtyardEffect(
      type: json['type'] as String,
      currency: json['currency'] as String?,
      amount: json['amount'] as num?,
      capIncrease: json['capIncrease'] as int?,
      friendSlots: json['friendSlots'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (currency != null) 'currency': currency,
        if (amount != null) 'amount': amount,
        if (capIncrease != null) 'capIncrease': capIncrease,
        if (friendSlots != null) 'friendSlots': friendSlots,
      };

  @override
  List<Object?> get props => [type, currency, amount, capIncrease, friendSlots];
}

/// Single courtyard facility entry.
/// This is meant to line up with your `courtyard_facilities.json` objects.
///
/// Typical JSON shape:
/// {
///   "id": "friends_board",
///   "area": "courtyard",
///   "group": "Friends Board",
///   "name": "Friends Board",
///   "description": "...",
///   "requiredStars": 0,
///   "requirementNote": "Sold during Christmas Event",   // optional
///   "price": [ { "currency": "film", "amount": 0 } ],
///   "effects": [
///     { "type": "friendLimitIncrease", "friendSlots": 10 },
///     { "type": "ratingBonus", "amount": 2 }
///   ],
///   "series": "Core Courtyard"
/// }
class CourtyardFacility extends Equatable {
  final String id;
  final String area; // should be "courtyard" for all of these
  final String group; // Friends Board, Speaker, Door, Plants, etc.
  final String name;
  final String description;

  /// Star requirement if you want to keep using that;
  /// you can set 0 in JSON if not applicable.
  final int requiredStars;

  /// Optional extra requirement text
  /// like "Sold During Christmas Event" or
  /// "Complete Aromatic Acorn 1-Star Judging".
  final String? requirementNote;

  final List<CourtyardPrice> price;
  final List<CourtyardEffect> effects;

  /// Series / theme – used for the left side of the Courtyard page.
  /// Can be things like "Log Scenery", "Candy", "Plants", etc.
  final String? series;

  const CourtyardFacility({
    required this.id,
    required this.area,
    required this.group,
    required this.name,
    required this.description,
    required this.requiredStars,
    required this.price,
    required this.effects,
    this.requirementNote,
    this.series,
  });

  factory CourtyardFacility.fromJson(Map<String, dynamic> json) {
    final priceJson = json['price'] as List<dynamic>? ?? const [];
    final effectsJson = json['effects'] as List<dynamic>? ?? const [];

    return CourtyardFacility(
      id: json['id'] as String,
      area: json['area'] as String? ?? 'courtyard',
      group: json['group'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      requiredStars: (json['requiredStars'] as num?)?.toInt() ?? 0,
      requirementNote: json['requirementNote'] as String?,
      series: json['series'] as String?,
      price: priceJson
          .map((e) => CourtyardPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
      effects: effectsJson
          .map((e) => CourtyardEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'area': area,
        'group': group,
        'name': name,
        'description': description,
        'requiredStars': requiredStars,
        if (requirementNote != null) 'requirementNote': requirementNote,
        if (series != null) 'series': series,
        'price': price.map((p) => p.toJson()).toList(),
        'effects': effects.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        area,
        group,
        name,
        description,
        requiredStars,
        requirementNote,
        price,
        effects,
        series,
      ];
}
