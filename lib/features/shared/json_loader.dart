// lib/features/shared/data/json_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonLoader {
  static final Map<String, dynamic> _cache = {};

  static Future<dynamic> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    final raw = await rootBundle.loadString(assetPath);
    final data = json.decode(raw);
    _cache[assetPath] = data;
    return data;
  }
}
