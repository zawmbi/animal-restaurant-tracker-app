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
  }

  Future<List<Dish>> all() => _ensure();

  Future<Dish?> byId(String id) async {
    await _ensure();
    final trimmedId = id.trim().toLowerCase();
    return _byId?[trimmedId];
  }

  Future<Dish?> byName(String name) async {
    await _ensure();
    return _byNameLower![name.toLowerCase()];
  }

  /// Accepts either the canonical dish id ("taiyaki") or a display name ("Taiyaki").
  Future<Dish?> resolve(String idOrName) async {
    await _ensure();
    final key = idOrName.trim();
    return _byId![key] ?? _byNameLower![key.toLowerCase()];
  }
}
