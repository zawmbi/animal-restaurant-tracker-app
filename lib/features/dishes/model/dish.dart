class Dish {
  final String id;
  final String name;

  // ex: ["Fresh Dishes"] or ["Buffet", "Takeout"]
  final List<String> sections;

  final String description;

  // Numeric-ish stats
  final int? timeSeconds;          // from time_s
  final int? earningsMax;          // from earnings_max
  final String? earningsPerHour;   // "+3,000/h" style
  final String? earningsRange;     // "+21~80" style
  final String? requirement;       // can be "110", "Piping Bag", etc.
  final String? costText;          // cost can be int, string, "Free", or null
  final int? refinedRating;        // refined_rating
  final String? ingredients;       // "Wheat (4); Rice (3)"
  final int? perfectDishes;        // perfect_dishes
  final int? prepTimeSeconds;      // prep_time_s
  final String? flavor;            // "Sweet", "Salty", etc.

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
    this.refinedRating,
    this.ingredients,
    this.perfectDishes,
    this.prepTimeSeconds,
    this.flavor,
  });

  /// Backward compatibility for older code that expected `dish.category`.
  /// We'll just say the "category" is the first section, e.g. "Fresh Dishes".
  String? get category {
    if (sections.isEmpty) return null;
    return sections.first;
  }

  factory Dish.fromJson(Map<String, dynamic> j) {
    // helper to safely turn dynamic into int?
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        // strip commas etc ("1,000" -> "1000")
        final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.isEmpty) return null;
        return int.tryParse(digitsOnly);
      }
      return null;
    }

    // cost can be int, string "Free", string "50", null...
    String? _asCostText(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    return Dish(
      id: j['id'] as String,
      name: j['name'] as String,
      sections: (j['sections'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      description: j['description'] as String? ?? '',

      timeSeconds: _asInt(j['time_s']),
      earningsMax: _asInt(j['earnings_max']),
      earningsPerHour: j['earnings_per_hour']?.toString(),
      earningsRange: j['earnings_range']?.toString(),
      requirement: j['requirement']?.toString(),
      costText: _asCostText(j['cost']),
      refinedRating: _asInt(j['refined_rating']),
      ingredients: j['ingredients']?.toString(),
      perfectDishes: _asInt(j['perfect_dishes']),
      prepTimeSeconds: _asInt(j['prep_time_s']),
      flavor: j['flavor']?.toString(),
    );
  }
}
