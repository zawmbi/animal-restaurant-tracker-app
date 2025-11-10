import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/dish.dart';

class DishesRepository {
  DishesRepository._();
  static final DishesRepository instance = DishesRepository._();

  // Cache + indexes
  List<Dish>? _cache;
  Map<String, Dish>? _byId;
  Map<String, Dish>? _byNameLower;

  Future<void> _ensure() async {
    if (_cache != null) return;
    _cache = await _loadAllFromAssets();
    _reindex();
  }

  void _reindex() {
    _byId = {for (final d in _cache!) d.id: d};
    _byNameLower = {
      for (final d in _cache!) d.name.toLowerCase(): d,
    };
  }

  // Adjust this to your actual asset path/loader if different.
  Future<List<Dish>> _loadAllFromAssets() async {
    final raw = await rootBundle.loadString('assets/data/dishes.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Dish>> all() async {
    await _ensure();
    return _cache!;
  }

  Future<Dish?> byId(String id) async {
    await _ensure();
    return _byId![id];
  }

  Future<Dish?> byName(String name) async {
    await _ensure();
    return _byNameLower![name.toLowerCase()];
  }

  /// Accepts either the canonical dish id ("taiyaki") or a display name ("Taiyaki").
  Future<Dish?> resolve(String idOrName) async {
    await _ensure();
    final key = idOrName.trim();
    return _byId![key] ?? _byNameLower![key.toLowerCase()];
  }
}
