import 'memento.dart';

/// Instead of a single classification, customers have **tags** so one
/// customer can belong to multiple groups (e.g., restaurant + nearby + holiday).
class Customer {
  final String id; // slug id, e.g., "white_bunny"
  final String name;
  final List<String> tags; // e.g., ["restaurant","nearby","very_common"]
  final String livesIn; // e.g., "Nearby"
  final int appearanceWeight; // e.g., 10000
  final String? requiredFoodId; // e.g., "taiyaki"
  final List<String> dishesOrderedIds; // e.g., ["taiyaki"]
  final List<Memento> mementos;

  const Customer({
    required this.id,
    required this.name,
    required this.tags,
    required this.livesIn,
    required this.appearanceWeight,
    required this.requiredFoodId,
    required this.dishesOrderedIds,
    required this.mementos,
  });

  bool hasTag(String tag) => tags.contains(tag);

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        name: j['name'] as String,
        tags: (j['tags'] as List? ?? const []).cast<String>(),
        livesIn: j['livesIn'] as String? ?? '',
        appearanceWeight: j['appearanceWeight'] as int? ?? 0,
        requiredFoodId: j['requiredFoodId'] as String?,
        dishesOrderedIds: (j['dishesOrderedIds'] as List? ?? const [])
            .cast<String>(),
        mementos: (j['mementos'] as List? ?? const [])
            .map((m) => Memento.fromJson(m))
            .toList(),
      );
}