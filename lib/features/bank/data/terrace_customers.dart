import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// A terrace customer, unlocked by promoting the Terrace.
class TerraceCustomer {
  final String id;
  final String name;
  final String description;

  /// Promo tier required on the Speaker: "Local", "Regional", "National".
  final String? promoLevel;

  /// Number of terrace promotions that guarantees this customer (pity system).
  final int promoCount;

  /// Dishes that must be unlocked for this customer to appear.
  final List<String> requiredFoods;

  /// All dishes this customer may order.
  final List<String> dishesOrdered;

  final int? appearanceWeight;

  const TerraceCustomer({
    required this.id,
    required this.name,
    required this.description,
    required this.promoLevel,
    required this.promoCount,
    required this.requiredFoods,
    required this.dishesOrdered,
    required this.appearanceWeight,
  });

  factory TerraceCustomer.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const <String>[];
    int? nInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return TerraceCustomer(
      id: j['id'].toString(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      promoLevel: j['promoLevel']?.toString(),
      promoCount: nInt(j['promoCount']) ?? 0,
      requiredFoods: strList(j['requiredFoods']),
      dishesOrdered: strList(j['dishesOrdered']),
      appearanceWeight: nInt(j['appearanceWeight']),
    );
  }
}

class TerraceCustomersRepository {
  TerraceCustomersRepository._();
  static final TerraceCustomersRepository instance =
      TerraceCustomersRepository._();

  List<TerraceCustomer>? _cache;

  Future<List<TerraceCustomer>> all() async {
    if (_cache != null) return _cache!;
    final raw =
        await rootBundle.loadString('assets/data/terrace_customers.json');
    final list = (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((e) => TerraceCustomer.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      // Show in unlock order (cheapest promo first).
      ..sort((a, b) => a.promoCount.compareTo(b.promoCount));
    _cache = list;
    return list;
  }
}
