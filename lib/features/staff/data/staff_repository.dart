import 'package:animal_restaurant_tracker/features/shared/json_loader.dart';
import '../model/staff_member.dart';

class StaffRepository {
  static const _asset = 'assets/data/staff.json';
  StaffRepository._();
  static final StaffRepository instance = StaffRepository._();

  List<StaffMember>? _cache;

  Future<List<StaffMember>> all() async {
    if (_cache != null) return _cache!;
    final data = await JsonLoader.load(_asset) as List<dynamic>;
    _cache = data
        .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return _cache!;
  }

  Future<StaffMember?> byId(String id) async {
    final list = await all();
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  }
}
