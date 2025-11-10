import 'package:flutter/foundation.dart';

/// Basic money tuple used by dishes & tiers.
@immutable
class Price {
  final String currency; // e.g. "cod", "plates"
  final int amount;

  const Price({required this.currency, required this.amount});

  factory Price.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return Price(
      currency: (json['currency'] ?? '').toString(),
      amount: rawAmount is int ? rawAmount : int.tryParse('$rawAmount') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'amount': amount,
      };
}

/// Optional tier (mainly for Takeout), keeping room for per-tier earnings.
@immutable
class DishTier {
  final String? tier; // "C","B","A","S" etc.
  final int? requirementsStars;
  final int? requirementsLikes;
  final List<Price>? price;
  final String? earningsRange; // Optional: "+14~56" etc. if provided per-tier.

  const DishTier({
    this.tier,
    this.requirementsStars,
    this.requirementsLikes,
    this.price,
    this.earningsRange,
  });

  factory DishTier.fromJson(Map<String, dynamic> json) => DishTier(
        tier: json['tier']?.toString(),
        requirementsStars: _asIntOrNull(json['requirementsStars']),
        requirementsLikes: _asIntOrNull(json['requirementsLikes']),
        price: (json['price'] is List)
            ? (json['price'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Price.fromJson(e))
                .toList()
            : null,
        earningsRange: json['earningsRange']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (tier != null) 'tier': tier,
        if (requirementsStars != null) 'requirementsStars': requirementsStars,
        if (requirementsLikes != null) 'requirementsLikes': requirementsLikes,
        if (price != null) 'price': price!.map((e) => e.toJson()).toList(),
        if (earningsRange != null) 'earningsRange': earningsRange,
      };
}

@immutable
class Dish {
  final String id;
  final String name;
  final List<String> sections;
  final String description;

  // Core numbers (nullable so older rows can omit them)
  final int? timeSeconds;
  final int? earningsMax;
  final String? earningsPerHour; // e.g. "+3,000/h"
  final String? earningsRange;   // e.g. "+14~56"

  // Requirements & cost (legacy)
  final String? requirement; // raw text like "400★" or other notes
  final String? costText;    // raw "Free", "400 Cod", etc.

  // New normalized fields used by the detail page
  final int? requirementsStars;     // numeric star requirement
  final List<Price>? price;         // normalized prices list
  final List<DishTier>? tiers;      // optional tiered unlocks

  // Food Truck / extras
  final int? refinedRating;
  final String? ingredients;    // stored raw; UI formats to chips
  final int? perfectDishes;
  final int? prepTimeSeconds;
  final String? flavor;

  const Dish({
    required this.id,
    required this.name,
    required this.sections,
    required this.description,
    this.timeSeconds,
    this.earningsMax,
    this.earningsPerHour,
    this.earningsRange,
    this.requirement,
    this.costText,
    this.requirementsStars,
    this.price,
    this.tiers,
    this.refinedRating,
    this.ingredients,
    this.perfectDishes,
    this.prepTimeSeconds,
    this.flavor,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sections: (json['sections'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      description: (json['description'] ?? '').toString(),

      timeSeconds: _asIntOrNull(json['timeSeconds'] ?? json['time_s']),
      earningsMax: _asIntOrNull(json['earningsMax']),
      earningsPerHour: json['earningsPerHour']?.toString(),
      earningsRange: json['earningsRange']?.toString(),

      // legacy/extra strings
      requirement: json['requirement']?.toString(),
      costText: json['cost']?.toString() ?? json['costText']?.toString(),

      // normalized new fields
      requirementsStars: _asIntOrNull(json['requirementsStars']),
      price: (json['price'] is List)
          ? (json['price'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Price.fromJson(e))
              .toList()
          : null,
      tiers: (json['tiers'] is List)
          ? (json['tiers'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DishTier.fromJson(e))
              .toList()
          : null,

      // food truck / extras
      refinedRating: _asIntOrNull(json['refinedRating']),
      ingredients: json['ingredients']?.toString(),
      perfectDishes: _asIntOrNull(json['perfectDishes']),
      prepTimeSeconds: _asIntOrNull(json['prepTimeSeconds']),
      flavor: json['flavor']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sections': sections,
        'description': description,
        if (timeSeconds != null) 'timeSeconds': timeSeconds,
        if (earningsMax != null) 'earningsMax': earningsMax,
        if (earningsPerHour != null) 'earningsPerHour': earningsPerHour,
        if (earningsRange != null) 'earningsRange': earningsRange,
        if (requirement != null) 'requirement': requirement,
        if (costText != null) 'cost': costText,
        if (requirementsStars != null) 'requirementsStars': requirementsStars,
        if (price != null) 'price': price!.map((e) => e.toJson()).toList(),
        if (tiers != null) 'tiers': tiers!.map((e) => e.toJson()).toList(),
        if (refinedRating != null) 'refinedRating': refinedRating,
        if (ingredients != null) 'ingredients': ingredients,
        if (perfectDishes != null) 'perfectDishes': perfectDishes,
        if (prepTimeSeconds != null) 'prepTimeSeconds': prepTimeSeconds,
        if (flavor != null) 'flavor': flavor,
      };
}

// ---- helpers ----
int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}
