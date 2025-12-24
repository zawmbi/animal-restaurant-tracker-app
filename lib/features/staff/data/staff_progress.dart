import 'package:shared_preferences/shared_preferences.dart';

class StaffProgress {
  StaffProgress._();
  static final StaffProgress instance = StaffProgress._();

  static const _prefix = 'staff_raise_checked';

  String _key(String staffId) => '$_prefix:$staffId';

  Future<Set<int>> checkedLevels(String staffId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key(staffId)) ?? const <String>[];
    return raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Future<void> setChecked(String staffId, int level, bool value) async {
    final sp = await SharedPreferences.getInstance();
    final set = await checkedLevels(staffId);
    if (value) {
      set.add(level);
    } else {
      set.remove(level);
    }
    final list = set.toList()..sort();
    await sp.setStringList(_key(staffId), list.map((e) => e.toString()).toList());
  }

  Future<int?> highestCheckedLevel(String staffId) async {
    final set = await checkedLevels(staffId);
    if (set.isEmpty) return null;
    final list = set.toList()..sort();
    return list.last;
  }

  Future<void> clearStaff(String staffId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(staffId));
  }
}
