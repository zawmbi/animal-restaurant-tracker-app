// lib/features/shared/utils/display_names.dart
//
// Turning raw data keys into something a player should actually read.
//
// Ids in the data are snake_case slugs ("hermit_crab") and currency keys are
// bare lowercase words ("plates"). Several detail pages were printing those
// straight into the UI.

import '../json_loader.dart';

/// "hermit_crab" -> "Hermit Crab". Leaves already-spaced names alone.
String prettyId(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// "plates" -> "Plates". Currency keys are single words, so this is just a
/// capitalisation, but it goes through one helper so every page agrees.
String prettyCurrency(String raw) => prettyId(raw);

/// Display names for fish ids, read from assets/data/fish.json.
///
/// Booth owners reference fish by id; the fish's real name only exists in
/// fish.json, so without this the customer page printed the raw slug.
class FishNames {
  FishNames._();
  static final FishNames instance = FishNames._();

  static const String _asset = 'assets/data/fish.json';
  Map<String, String>? _byId;
  Future<Map<String, String>>? _future;

  Future<Map<String, String>> load() => _future ??= _load();

  Future<Map<String, String>> _load() async {
    try {
      final raw = await JsonLoader.load(_asset) as List<dynamic>;
      final out = <String, String>{};
      for (final e in raw) {
        if (e is Map && e['id'] != null) {
          out[e['id'].toString()] =
              (e['name'] ?? prettyId(e['id'].toString())).toString();
        }
      }
      _byId = out;
      return out;
    } catch (_) {
      _future = null; // allow a retry
      rethrow;
    }
  }

  /// Synchronous lookup for widgets that already triggered [load].
  /// Falls back to prettifying the id so a missing entry still reads well.
  String nameFor(String id) => _byId?[id] ?? prettyId(id);
}
