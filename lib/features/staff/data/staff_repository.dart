import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/staff_member.dart';

class StaffRepository {
  static const _asset = 'assets/data/staff.json';
  StaffRepository._();
  static final StaffRepository instance = StaffRepository._();

  List<StaffMember>? _cache;

  /// Cached *future* so concurrent callers share one load + parse, and so
  /// `FutureBuilder`s that call `all()` from `build()` see a stable Future.
  Future<List<StaffMember>>? _future;

  Future<List<StaffMember>> all() => _future ??= _load();

  Future<List<StaffMember>> _load() async {
    try {
      final data = await JsonLoader.load(_asset) as List<dynamic>;
      final out = data
          .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
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
  List<StaffMember>? get cached => _cache;

  Future<StaffMember?> byId(String id) async {
    final list = await all();
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  }
}
