// ignore_for_file: prefer_is_not_operator

import '../../shared/json_loader.dart';
import '../model/facility.dart';

class FacilitiesRepository {
  FacilitiesRepository._();
  static final FacilitiesRepository instance = FacilitiesRepository._();

  /// Shards per area. (Veg garden shards are treated as the same `garden` area.)
  /// Signature Store lives inside Takeout, so we include it in the Takeout shard list.
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

      // Signature Store lives inside Takeout.
      'assets/data/facilities_jsons/signature_store_facilities.json',
    ],
    FacilityArea.terrace: [
      'assets/data/facilities_jsons/terrace_facilities.json',
    ],
    // Courtyard shards exist in assets, but your UI excludes them.
    FacilityArea.courtyard: [
      'assets/data/facilities_jsons/courtyard_facilities.json',
    ],
    FacilityArea.courtyard_concert: [
      'assets/data/facilities_jsons/concert_facilities.json',
    ],
    FacilityArea.courtyard_pets: [
      'assets/data/facilities_jsons/pets_facilities.json',
    ],
  };

  final Map<FacilityArea, List<Facility>> _byArea = {};

  /// Cached *futures*, not just results: `byArea` is called straight from
  /// `FacilitiesPage.build()` and concurrently by `all()`, so without this two
  /// callers would each load and decode the same shard.
  final Map<FacilityArea, Future<List<Facility>>> _byAreaFutures = {};

  List<Facility>? _allCache;
  Future<List<Facility>>? _allFuture;

  /// Load and merge shards for a single area (cached).
  Future<List<Facility>> byArea(FacilityArea area) =>
      _byAreaFutures[area] ??= _loadArea(area);

  Future<List<Facility>> _loadArea(FacilityArea area) async {
    try {
      final paths = _assetsForArea[area] ?? const <String>[];
      final out = <Facility>[];

      for (final path in paths) {
        final decoded = await _tryLoad(path);
        if (decoded == null) {
          // If a shard path doesn't exist (e.g., fallback not needed), skip quietly.
          continue;
        }

        if (decoded is! List) {
          throw FormatException('Facility shard is not a JSON list: $path');
        }

        final list = decoded.cast<Map<String, dynamic>>();

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
      return out;
    } catch (_) {
      _byAreaFutures.remove(area); // allow a retry
      rethrow;
    }
  }

  /// Merge all areas (cached). Includes Signature Store automatically via Takeout shards.
  Future<List<Facility>> all() => _allFuture ??= _loadAll();

  Future<List<Facility>> _loadAll() async {
    try {
      final lists = await Future.wait(_assetsForArea.keys.map(byArea));
      final merged = lists.expand((e) => e).toList(growable: false);
      _allCache = merged;
      return merged;
    } catch (_) {
      _allFuture = null; // allow a retry
      rethrow;
    }
  }

  /// Synchronously available once [all] has completed.
  List<Facility>? get cached => _allCache;

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
    _byAreaFutures.clear();
    _allCache = null;
    _allFuture = null;
  }

  /// Decodes a shard through [JsonLoader] (shared cache + off-main-isolate
  /// decode for the big shards), returning null if the asset doesn't exist.
  /// This lets us include optional fallback paths safely.
  Future<dynamic> _tryLoad(String path) async {
    try {
      return await JsonLoader.load(path);
    } on FormatException {
      rethrow; // malformed JSON is a real error, as before
    } catch (_) {
      return null; // shard simply isn't bundled
    }
  }
}
