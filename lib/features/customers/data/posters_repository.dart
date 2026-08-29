import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/poster.dart';

class PostersRepository {
  static const _asset = 'assets/data/posters.json';
  PostersRepository._();
  static final PostersRepository instance = PostersRepository._();

  List<Poster>? _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<Poster>>? _future;

  Future<List<Poster>> all() => _future ??= _load();

  Future<List<Poster>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out =
          data.map((e) => Poster.fromJson(e as Map<String, dynamic>)).toList();
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
  List<Poster>? get cached => _cache;

  Future<Poster?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
