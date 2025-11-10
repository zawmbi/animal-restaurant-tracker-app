import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/facility.dart';

class FacilitiesRepository {
  FacilitiesRepository._();
  static final FacilitiesRepository instance = FacilitiesRepository._();

  // Map each area to its shard file.
  static const Map<FacilityArea, String> _assetForArea = {
    FacilityArea.restaurant: 'assets/data/facilities/restaurant_facilities.json',
    FacilityArea.kitchen:    'assets/data/facilities/kitchen_facilities.json',
    FacilityArea.garden:     'assets/data/facilities/garden_facilities.json',
    FacilityArea.buffet:     'assets/data/facilities/buffet_facilities.json',
    FacilityArea.takeout:    'assets/data/facilities/takeout_facilities.json',
    FacilityArea.terrace:    'assets/data/facilities/terrace_facilities.json',
    // Courtyard shards intentionally excluded per your requirement.
  };

  // Caches
  final Map<FacilityArea, List<Facility>> _byArea = {};
  List<Facility>? _allCache;

  /// Load every shard and return a single merged list (cached).
  Future<List<Facility>> all() async {
    if (_allCache != null) return _allCache!;
    final loads = <Future<List<Facility>>>[];
    for (final area in _assetForArea.keys) {
      loads.add(byArea(area));
    }
    final lists = await Future.wait(loads);
    _allCache = lists.expand((e) => e).toList(growable: false);
    return _allCache!;
  }

  /// Load a single shard for the given area (cached).
  Future<List<Facility>> byArea(FacilityArea area) async {
    if (_byArea.containsKey(area)) return _byArea[area]!;
    final path = _assetForArea[area];
    if (path == null) return const <Facility>[];

    final raw = await rootBundle.loadString(path);
    final jsonList = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    // Ensure every row has an "area" for Facility.fromJson
    final rows = jsonList.map((m) {
      if (!m.containsKey('area') || (m['area'] == null || '${m['area']}'.isEmpty)) {
        return {...m, 'area': area.name};
      }
      return m;
    }).toList();

    final list = rows.map((m) => Facility.fromJson(m)).toList();
    _byArea[area] = list;
    // Invalidate merged cache since we added a shard lazily.
    _allCache = null;
    return list;
  }

  /// Clear caches and reload next call.
  Future<void> reload() async {
    _byArea.clear();
    _allCache = null;
  }
}
