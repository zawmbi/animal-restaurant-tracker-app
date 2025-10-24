class Dish {
  final String id; // e.g., "taiyaki"
  final String name;
  final String? category; // optional, e.g., "dessert"

  const Dish({required this.id, required this.name, this.category});

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String?,
      );
}