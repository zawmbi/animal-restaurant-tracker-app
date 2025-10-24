// lib/features/facilities/data/facilities_repository.dart

import '../../../shared/json_loader.dart'; // <-- keep this one
import '../../model/facility.dart';

class FacilitiesRepository {
  static const _asset = 'assets/data/facilities.json';
  FacilitiesRepository._();
  static final FacilitiesRepository instance = FacilitiesRepository._();
  List<Facility>? _cache;

  Future<List<Facility>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => Facility.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
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
