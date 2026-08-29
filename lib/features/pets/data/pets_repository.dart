import '../../shared/json_loader.dart';
import '../model/pet.dart';

class PetsRepository {
  PetsRepository._();
  static final PetsRepository instance = PetsRepository._();

  static const _asset = 'assets/data/pets.json';

  PetsData? _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `load()` from `build()` see a stable Future.
  Future<PetsData>? _future;

  Future<PetsData> load() => _future ??= _doLoad();

  Future<PetsData> _doLoad() async {
    try {
      final data = await JsonLoader.load(_asset) as Map<String, dynamic>;
      final out = PetsData.fromJson(data);
      // Sole consumer of this asset; the parsed models replace the raw maps.
      JsonLoader.evict(_asset);
      _cache = out;
      return out;
    } catch (_) {
      _future = null; // allow a retry
      rethrow;
    }
  }

  /// Synchronously available once [load] has completed.
  PetsData? get cached => _cache;
}
