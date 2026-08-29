// lib/features/letters/data/letters_repository.dart
import '../../shared/json_loader.dart';
import '../model/letter.dart';

class LettersRepository {
  static const _asset = 'assets/data/letters.json';

  LettersRepository._();
  static final LettersRepository instance = LettersRepository._();

  List<Letter>? _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<Letter>>? _future;

  Future<List<Letter>> all() => _future ??= _load();

  Future<List<Letter>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out =
          data.map((e) => Letter.fromJson(e as Map<String, dynamic>)).toList();
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
  List<Letter>? get cached => _cache;

  Future<Letter?> byId(String id) async {
    final list = await all();
    for (final l in list) {
      if (l.id == id) return l;
    }
    return null;
  }
}
