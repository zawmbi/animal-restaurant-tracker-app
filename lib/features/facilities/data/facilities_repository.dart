import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/facility.dart';

class FacilitiesRepository {
  FacilitiesRepository._();
  static final FacilitiesRepository instance = FacilitiesRepository._();

  /// Shards per area. (Veg garden shards are treated as the same `garden` area.)
  static const Map<FacilityArea, List<String>> _assetsForArea = {
    FacilityArea.restaurant: [
      'assets/data/facilities_jsons/restaurant_facilities.json',
    ],
    FacilityArea.kitchen: [
      'assets/data/facilities_jsons/kitchen_facilities.json',
    ],
    FacilityArea.garden: [
      'assets/data/facilities_jsons/garden_facilities.json',
      'assets/data/facilities_jsons/vegetable_garden_facilities.json',
    ],
    FacilityArea.buffet: [
      'assets/data/facilities_jsons/buffet_facilities.json',
    ],
    FacilityArea.takeout: [
      'assets/data/facilities_jsons/takeout_facilities.json',
    ],
    FacilityArea.terrace: [
      'assets/data/facilities_jsons/terrace_facilities.json',
    ],
    // Courtyard shards exist in assets, but your UI excludes them.
    FacilityArea.courtyard: [
      'assets/data/facilities_jsons/courtyard_facilities.json',
    ],
    FacilityArea.courtyard_concert: [],
    FacilityArea.courtyard_pets: [],
  };

  final Map<FacilityArea, List<Facility>> _byArea = {};
  List<Facility>? _allCache;

  /// Load and merge shards for a single area (cached).
  Future<List<Facility>> byArea(FacilityArea area) async {
    if (_byArea.containsKey(area)) return _byArea[area]!;
    final paths = _assetsForArea[area] ?? const <String>[];
    final out = <Facility>[];

    for (final path in paths) {
      final raw = await rootBundle.loadString(path);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

      // Ensure correct 'area' string in each row for Facility.fromJson
      for (final m in list) {
        final withArea = {
          ...m,
          if (!(m['area'] is String) || (m['area'] as String).trim().isEmpty)
            'area': area.name,
        };
        out.add(Facility.fromJson(withArea));
      }
    }

    _byArea[area] = out;
    _allCache = null; // invalidate merged cache
    return out;
  }

  /// Merge all areas (cached). Still reads only from facilities_jsons/.
  Future<List<Facility>> all() async {
    if (_allCache != null) return _allCache!;
    final lists = await Future.wait(_assetsForArea.keys.map(byArea));
    _allCache = lists.expand((e) => e).toList(growable: false);
    return _allCache!;
  }

  /// Find a facility by id across all areas.
  Future<Facility?> byId(String id) async {
    final allItems = await all();
    try {
      return allItems.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear caches after you edit JSON during development.
  Future<void> reload() async {
    _byArea.clear();
    _allCache = null;
  }
}
