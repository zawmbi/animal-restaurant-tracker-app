import '../../shared/json_loader.dart';
import '../model/movie.dart';

class MoviesRepository {
  MoviesRepository._();
  static final MoviesRepository instance = MoviesRepository._();

  static const String _asset = 'assets/data/movies.json';

  List<Movie>? _cache;

  Future<List<Movie>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  Future<Movie?> byId(String id) async {
    final list = await all();
    for (final m in list) {
      if (m.id == id) return m;
    }
    return null;
  }
}
