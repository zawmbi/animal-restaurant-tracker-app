import 'package:flutter/material.dart';

import '../../dishes/data/dishes_repository.dart';
import '../../dishes/ui/dish_detail_page.dart' as dish_ui;

import '../../facilities/data/facilities_repository.dart';
import '../../facilities/ui/facility_detail_page.dart' as fac_ui;

/// Tries to turn a line of text into a navigation action.
/// If it can resolve a dish/facility, it navigates and returns true.
/// Otherwise returns false.
class EntityLinker {
  EntityLinker._();
  static final EntityLinker instance = EntityLinker._();

  List<dynamic>? _dishCache; // List<Dish> (kept dynamic to avoid importing model)
  List<dynamic>? _facilityCache;

  Future<void> _ensureDishCache() async {
    _dishCache ??= await DishesRepository.instance.all();
  }

  Future<void> _ensureFacilityCache() async {
    _facilityCache ??= await FacilitiesRepository.instance.all();
  }

  String? _extractDishName(String line) {
    final l = line.trim();
    if (l.startsWith('Learn recipe:')) return l.replaceFirst('Learn recipe:', '').trim();
    if (l.startsWith('Learn buffet:')) return l.replaceFirst('Learn buffet:', '').trim();
    if (l.startsWith('Learn:')) return l.replaceFirst('Learn:', '').trim();
    return null;
  }

  String? _extractFacilityName(String line) {
    final l = line.trim();
    if (l.startsWith('Must unlock ')) return l.replaceFirst('Must unlock ', '').trim();
    if (l.startsWith('Must unlock:')) return l.replaceFirst('Must unlock:', '').trim();
    if (l.startsWith('Unlock:')) return l.replaceFirst('Unlock:', '').trim();
    return null;
  }

  Future<String?> _findDishIdByName(String name) async {
    await _ensureDishCache();
    final q = name.toLowerCase();

    for (final d in _dishCache!) {
      // assumes Dish has .id and .name
      final dn = (d.name as String).toLowerCase();
      if (dn == q) return d.id as String;
    }
    // fallback: contains
    for (final d in _dishCache!) {
      final dn = (d.name as String).toLowerCase();
      if (dn.contains(q) || q.contains(dn)) return d.id as String;
    }
    return null;
  }

  Future<String?> _findFacilityIdByName(String name) async {
    await _ensureFacilityCache();
    final q = name.toLowerCase();

    for (final f in _facilityCache!) {
      // assumes Facility has .id and .name
      final fn = (f.name as String).toLowerCase();
      if (fn == q) return f.id as String;
    }
    // fallback: contains
    for (final f in _facilityCache!) {
      final fn = (f.name as String).toLowerCase();
      if (fn.contains(q) || q.contains(fn)) return f.id as String;
    }
    return null;
  }

  Future<bool> openFromLine(BuildContext context, String line) async {
    final dishName = _extractDishName(line);
    if (dishName != null && dishName.isNotEmpty) {
      final id = await _findDishIdByName(dishName);
      if (id != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => dish_ui.DishDetailPage(dishId: id)),
        );
        return true;
      }
    }

    final facilityName = _extractFacilityName(line);
    if (facilityName != null && facilityName.isNotEmpty) {
      final id = await _findFacilityIdByName(facilityName);
      if (id != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => fac_ui.FacilityDetailPage(facilityId: id)),
        );
        return true;
      }
    }

    return false;
  }

  /// Quick check for whether a line *looks* linkable (for showing a link icon).
  bool looksLinkable(String line) {
    return _extractDishName(line) != null || _extractFacilityName(line) != null;
  }
}
