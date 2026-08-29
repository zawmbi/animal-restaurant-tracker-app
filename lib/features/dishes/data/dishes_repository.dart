import '../../shared/json_loader.dart';
import '../model/dish.dart';

class DishesRepository {
  DishesRepository._();
  static final DishesRepository instance = DishesRepository._();

  static const String _asset = 'assets/data/dishes.json';

  // Cache + indexes
  List<Dish>? _cache;
  Map<String, Dish>? _byId;
  Map<String, Dish>? _byNameLower;
  Map<String, Dish>? _bySlug;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<Dish>>? _future;

  Future<List<Dish>> _ensure() => _future ??= _load();

  Future<List<Dish>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out =
          data.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
      // Sole consumer of this asset; the parsed models replace the raw maps.
      JsonLoader.evict(_asset);
      _cache = out;
      _reindex();
      return out;
    } catch (_) {
      _future = null; // allow a retry
      rethrow;
    }
  }

  void _reindex() {
    _byId = {for (final d in _cache!) d.id.toLowerCase(): d};
    _byNameLower = {
      for (final d in _cache!) d.name.toLowerCase(): d,
    };
    // Display name slugified the same way ids are, so "Adzuki Bean Dumpling"
    // also resolves via "adzuki_bean_dumpling".
    _bySlug = {
      for (final d in _cache!) _slugify(d.name): d,
    };
  }

  static String _slugify(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<List<Dish>> all() => _ensure();

  /// Looks up by canonical id, and falls back to display name and to the
  /// slugified display name.
  ///
  /// Callers pass whatever the data gave them, and the data is not
  /// consistent: every one of the 725 `requirements.recipes` entries on
  /// customers is a display name ("Taiyaki"), not an id. Matching on id
  /// alone made those chips dead-end on "Recipe not found".
  Future<Dish?> byId(String id) async {
    await _ensure();
    final key = id.trim();
    final lower = key.toLowerCase();
    return _byId?[lower] ?? _byNameLower?[lower] ?? _bySlug?[_slugify(key)];
  }

  Future<Dish?> byName(String name) async {
    await _ensure();
    return _byNameLower![name.toLowerCase()];
  }

  /// Accepts either the canonical dish id ("taiyaki") or a display name ("Taiyaki").
  Future<Dish?> resolve(String idOrName) async {
    await _ensure();
    final key = idOrName.trim();
    return _byId![key.toLowerCase()] ??
        _byNameLower![key.toLowerCase()] ??
        _bySlug![_slugify(key)];
  }
}
