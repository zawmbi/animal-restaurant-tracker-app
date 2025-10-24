import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Tiny cached loader for JSON assets.
class JsonLoader {
  static final Map<String, dynamic> _cache = {};

  static Future<dynamic> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw);
    _cache[assetPath] = decoded;
    return decoded;
  }
}