import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one terrace number the game will not tell you: what a gather actually
/// paid, observed in the player's own restaurant.
///
/// The Bank page has always collected this, because it is the only honest way
/// to put a cod figure on the terrace — the base payment per customer is
/// unpublished, so every projection has to be anchored to something the player
/// saw with their own eyes. It used to live in a `TextEditingController` and
/// die with the page, which meant the facility detail pages could not use it.
/// It is persisted here so both can.
class TerraceObservationStore extends ChangeNotifier {
  TerraceObservationStore._();
  static final TerraceObservationStore instance = TerraceObservationStore._();

  static const String _key = 'terrace_observed_cod_per_gather';

  double _codPerGather = 0;
  bool _loaded = false;
  Future<void>? _loadFuture;

  /// Observed cod from a single terrace gather. Zero means "not recorded",
  /// which callers must treat as "say nothing" rather than "zero income".
  double get codPerGather => _codPerGather;

  bool get hasObservation => _codPerGather > 0;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _codPerGather = prefs.getDouble(_key) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCodPerGather(double value) async {
    final next = value.isFinite && value > 0 ? value : 0.0;
    if (next == _codPerGather) return;
    _codPerGather = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (next > 0) {
      await prefs.setDouble(_key, next);
    } else {
      await prefs.remove(_key);
    }
  }

  @visibleForTesting
  void debugResetForTest() {
    _codPerGather = 0;
    _loaded = false;
    _loadFuture = null;
  }
}
