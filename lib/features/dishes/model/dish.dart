import 'package:flutter/foundation.dart';

@immutable
class Price {
  final String currency; // e.g. "cod", "plates", "bells"
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

@immutable
class DishTier {
  final String? tier; // "C","B","A","S" etc.
  final int? requiredStars;
  final int? requirementsLikes;
  final List<Price>? price;
  final String? earningsRange; // optional if you ever use it per-tier

  const DishTier({
    this.tier,
    this.requiredStars,
    this.requirementsLikes,
    this.price,
    this.earningsRange,
  });

  factory DishTier.fromJson(Map<String, dynamic> json) => DishTier(
        tier: json['tier']?.toString(),
        requiredStars: _asIntOrNull(json['requiredStars']),
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
        if (requiredStars != null) 'requiredStars': requiredStars,
        if (requirementsLikes != null) 'requirementsLikes': requirementsLikes,
        if (price != null) 'price': price!.map((e) => e.toJson()).toList(),
        if (earningsRange != null) 'earningsRange': earningsRange,
      };
}

@immutable
class DishIngredient {
  final String item;
  final int? amount;

  const DishIngredient({required this.item, this.amount});

  factory DishIngredient.fromJson(Map<String, dynamic> json) => DishIngredient(
        item: (json['item'] ?? '').toString(),
        amount: _asIntOrNull(json['amount']),
      );

  Map<String, dynamic> toJson() => {
        'item': item,
        if (amount != null) 'amount': amount,
      };
}

@immutable
class Dish {
  final String id;
  final String name;
  final List<String> sections;
  final String description;

  // Freshly Made
  final int? timeSeconds;
  final int? earningsMax;

  // Buffet
  final String? earningsPerHour; // string source if you keep it
  final int? earningsPerHourInt; // normalized numeric (Cod+/h)

  // Takeout
  final String? earningsRange; // e.g. "Bells+14~56"
  final int? requirementsLikes;

  // Requirements & cost (legacy)
  final String? requirement;
  final String? costText;

  // Normalized
  final int? requiredStars;
  final List<Price>? price;
  final List<DishTier>? tiers;

  // Food Truck Recipes
  final int? refinedRating;
  final List<DishIngredient>? ingredientsList;
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
    this.earningsPerHourInt,
    this.earningsRange,
    this.requirement,
    this.costText,
    this.requiredStars,
    this.requirementsLikes,
    this.price,
    this.tiers,
    this.refinedRating,
    this.ingredientsList,
    this.perfectDishes,
    this.prepTimeSeconds,
    this.flavor,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    // buffet: your JSON uses earningsPerHour as an int; sometimes you had "Cod+3,000/h" text elsewhere
    final ePHRaw = json['earningsPerHour'];
    final ePHInt = _asIntOrNull(ePHRaw);

    // food truck: ingredients is a list of {item, amount}
    List<DishIngredient>? ing;
    if (json['ingredients'] is List) {
      ing = (json['ingredients'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => DishIngredient.fromJson(e))
          .toList();
    }

    return Dish(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sections: (json['sections'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      description: (json['description'] ?? '').toString(),

      timeSeconds: _asIntOrNull(json['timeSeconds'] ?? json['time_s']),
      earningsMax: _asIntOrNull(json['earningsMax']),

      earningsPerHour: (ePHRaw is String) ? ePHRaw : null,
      earningsPerHourInt: ePHInt,

      earningsRange: json['earningsRange']?.toString(),

      requirement: json['requirement']?.toString(),
      costText: json['cost']?.toString() ?? json['costText']?.toString(),

      requiredStars: _asIntOrNull(json['requiredStars']),
      requirementsLikes: _asIntOrNull(json['requirementsLikes']),

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

      refinedRating: _asIntOrNull(json['refinedRating']),
      ingredientsList: ing,
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
        if (earningsPerHourInt != null) 'earningsPerHour': earningsPerHourInt,
        if (earningsRange != null) 'earningsRange': earningsRange,
        if (requirement != null) 'requirement': requirement,
        if (costText != null) 'cost': costText,
        if (requiredStars != null) 'requiredStars': requiredStars,
        if (requirementsLikes != null) 'requirementsLikes': requirementsLikes,
        if (price != null) 'price': price!.map((e) => e.toJson()).toList(),
        if (tiers != null) 'tiers': tiers!.map((e) => e.toJson()).toList(),
        if (refinedRating != null) 'refinedRating': refinedRating,
        if (ingredientsList != null)
          'ingredients': ingredientsList!.map((e) => e.toJson()).toList(),
        if (perfectDishes != null) 'perfectDishes': perfectDishes,
        if (prepTimeSeconds != null) 'prepTimeSeconds': prepTimeSeconds,
        if (flavor != null) 'flavor': flavor,
      };
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}
