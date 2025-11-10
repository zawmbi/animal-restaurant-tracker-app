import 'package:flutter/foundation.dart';
import 'memento.dart';

@immutable
class Customer {
  final String id;
  final String name;
  final List<String> tags;
  final String? livesIn;

  // ✅ this covers both your JSON "description" or "customerDescription"
  final String? description;
  String? get customerDescription => description;

  final int? appearanceWeight;
  final String? requiredFoodId;
  final List<String>? dishesOrderedIds;
  final List<Memento> mementos;

  const Customer({
    required this.id,
    required this.name,
    required this.tags,
    this.livesIn,
    this.description,
    this.appearanceWeight,
    this.requiredFoodId,
    this.dishesOrderedIds,
    this.mementos = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tags: (json['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
      livesIn: json['livesIn']?.toString(),
      // 👇 support both keys
      description: (json['customerDescription'] ??
              json['description'] ??
              '')
          .toString(),
      appearanceWeight: json['appearanceWeight'] is int
          ? json['appearanceWeight']
          : int.tryParse('${json['appearanceWeight']}'),
      requiredFoodId: json['requiredFoodId']?.toString(),
      dishesOrderedIds: (json['dishesOrderedIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mementos: (json['mementos'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Memento.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
        if (livesIn != null) 'livesIn': livesIn,
        if (description != null) 'customerDescription': description,
        if (appearanceWeight != null)
          'appearanceWeight': appearanceWeight,
        if (requiredFoodId != null) 'requiredFoodId': requiredFoodId,
        if (dishesOrderedIds != null)
          'dishesOrderedIds': dishesOrderedIds,
      };

  bool hasTag(String tag) => tags.contains(tag);
}
