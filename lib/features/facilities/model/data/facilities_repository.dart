import '../../../shared/json_loader.dart';
import '../../model/facility.dart';

class FacilitiesRepository {
  static const _asset = 'assets/data/facilities.json';
  FacilitiesRepository._();
  static final FacilitiesRepository instance = FacilitiesRepository._();

  List<Facility>? _cache;
  List<Facility>? get cached => _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<Facility>>? _future;

  Future<List<Facility>> all() => _future ??= _load();

  Future<List<Facility>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out =
          data.map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList();
      // Sole consumer of this asset; the parsed models replace the raw maps.
      JsonLoader.evict(_asset);
      _cache = out;
      return out;
    } catch (e) {
      _future = null; // allow a retry
      throw Exception('Error loading $_asset: $e');
    }
  }

  Future<Facility?> byId(String id) async {
    final list = await all();
    try {
      return list.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
