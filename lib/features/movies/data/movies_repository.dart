import '../../shared/json_loader.dart';
import '../model/movie.dart';

class MoviesRepository {
  MoviesRepository._();
  static final MoviesRepository instance = MoviesRepository._();

  static const String _asset = 'assets/data/movies.json';

  List<Movie>? _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<Movie>>? _future;

  Future<List<Movie>> all() => _future ??= _load();

  Future<List<Movie>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out = data
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      // Sole consumer of this asset; the parsed models replace the raw maps.
      JsonLoader.evict(_asset);
      _cache = out;
      return out;
    } catch (_) {
      _future = null; // allow a retry
      rethrow;
    }
  }

  /// Synchronously available once [all] has completed.
  List<Movie>? get cached => _cache;

  Future<Movie?> byId(String id) async {
    final list = await all();
    for (final m in list) {
      if (m.id == id) return m;
    }
    return null;
  }
}
