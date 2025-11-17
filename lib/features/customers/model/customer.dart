import 'memento.dart';

/// Flexible requirements for unlocking / showing a customer.
///
/// All fields are optional. If they are empty, it means
/// there is no requirement of that type.
class CustomerRequirements {
  final List<String> letters;
  final List<String> facilities;
  final List<String> recipes;
  final List<String> customers;
  final List<String> flowers;

  /// Restaurant rating requirement (e.g. 920 for White Shiba).
  final int? rating;

  const CustomerRequirements({
    this.letters = const [],
    this.facilities = const [],
    this.recipes = const [],
    this.customers = const [],
    this.flowers = const [],
    this.rating,
  });

  bool get hasAny =>
      (rating != null && rating! > 0) ||
      letters.isNotEmpty ||
      facilities.isNotEmpty ||
      recipes.isNotEmpty ||
      customers.isNotEmpty ||
      flowers.isNotEmpty;

  factory CustomerRequirements.fromJson(Map<String, dynamic> json) {
    List<String> _asStringList(dynamic value) {
      if (value == null) return const [];
      return (value as List).map((e) => e.toString()).toList();
    }

    return CustomerRequirements(
      letters: _asStringList(json['letters']),
      facilities: _asStringList(json['facilities']),
      recipes: _asStringList(json['recipes']),
      customers: _asStringList(json['customers']),
      flowers: _asStringList(json['flowers']),
      rating: (json['rating'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null && rating! > 0) map['rating'] = rating;
    if (letters.isNotEmpty) map['letters'] = letters;
    if (facilities.isNotEmpty) map['facilities'] = facilities;
    if (recipes.isNotEmpty) map['recipes'] = recipes;
    if (customers.isNotEmpty) map['customers'] = customers;
    if (flowers.isNotEmpty) map['flowers'] = flowers;
    return map;
  }
}

class Customer {
  final String id;
  final String name;
  final List<String> tags;
  final String livesIn;
  final int appearanceWeight;
  final String? requiredFoodId;
  final List<String> dishesOrderedIds;
  final String customerDescription;
  final List<Memento> mementos;

  /// Optional requirements for this customer.
  final CustomerRequirements? requirements;

  const Customer({
    required this.id,
    required this.name,
    required this.tags,
    required this.livesIn,
    required this.appearanceWeight,
    required this.requiredFoodId,
    required this.dishesOrderedIds,
    required this.customerDescription,
    required this.mementos,
    this.requirements,
  });

  /// Helper used by repositories / filters.
  bool hasTag(String tag) => tags.contains(tag);

  factory Customer.fromJson(Map<String, dynamic> json) {
    List<String> _asStringList(dynamic value) {
      if (value == null) return const [];
      return (value as List).map((e) => e.toString()).toList();
    }

    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      tags: _asStringList(json['tags']),
      livesIn: json['livesIn'] as String,
      appearanceWeight: (json['appearanceWeight'] as num).toInt(),
      requiredFoodId: json['requiredFoodId'] as String?,
      dishesOrderedIds: _asStringList(json['dishesOrderedIds']),
      customerDescription: (json['customerDescription'] as String?) ?? '',
      mementos: (json['mementos'] as List<dynamic>? ?? const [])
          .map((e) => Memento.fromJson(e as Map<String, dynamic>))
          .toList(),
      requirements: json['requirements'] != null
          ? CustomerRequirements.fromJson(
              json['requirements'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  // NOTE: no toJson() here on purpose, so we don't need Memento.toJson.
}
