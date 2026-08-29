import 'dart:convert';
import 'dart:io';

/// Reads a shipped JSON asset straight off disk.
///
/// `flutter test` runs with the package root as its working directory, so this
/// is the same bytes `rootBundle` would hand the app — without needing the
/// asset bundle, an isolate for `compute`, or any repository cache.
dynamic readAsset(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw StateError(
      'Missing asset $relativePath. Run `flutter test` from the package root.',
    );
  }
  return json.decode(file.readAsStringSync());
}

List<Map<String, dynamic>> readJsonList(String relativePath) {
  final decoded = readAsset(relativePath);
  if (decoded is! List) {
    throw StateError('$relativePath is not a JSON list');
  }
  return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Map<String, dynamic> readJsonMap(String relativePath) {
  final decoded = readAsset(relativePath);
  if (decoded is! Map) {
    throw StateError('$relativePath is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

/// Shards, in the same grouping `FacilitiesRepository._assetsForArea` uses.
const Map<String, List<String>> facilityShardsByArea = <String, List<String>>{
  'restaurant': ['restaurant_facilities.json'],
  'kitchen': ['kitchen_facilities.json'],
  'garden': ['garden_facilities.json', 'vegetable_garden_facilities.json'],
  'buffet': ['buffet_facilities.json'],
  'takeout': ['takeout_facilities.json', 'signature_store_facilities.json'],
  'terrace': ['terrace_facilities.json'],
  'courtyard': ['courtyard_facilities.json'],
  'courtyard_concert': ['concert_facilities.json'],
  'courtyard_pets': ['pets_facilities.json'],
};

/// The areas `FacilitiesPage` shows and `CompletionService._facilityScenes`
/// counts into the `facility` bucket.
const List<String> facilitySceneAreas = <String>[
  'restaurant',
  'kitchen',
  'garden',
  'buffet',
  'takeout',
  'terrace',
];

List<Map<String, dynamic>> facilityRowsForArea(String area) {
  final rows = <Map<String, dynamic>>[];
  for (final shard in facilityShardsByArea[area]!) {
    rows.addAll(readJsonList('assets/data/facilities_jsons/$shard'));
  }
  return rows;
}
