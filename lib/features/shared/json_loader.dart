// lib/features/shared/json_loader.dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

/// Top-level (not a closure / instance tear-off) so it can be handed to
/// [compute] and executed on a background isolate.
dynamic _decodeJson(String source) => json.decode(source);

/// Loads and decodes JSON assets, sharing work between callers.
///
/// Two properties matter for performance here:
///
/// * The cache holds the *future*, not the resolved value. Two widgets that
///   ask for the same asset before the first load has finished now share one
///   load + one decode instead of each doing their own (the classic
///   "cached the result but not the in-flight future" race).
/// * Large payloads are decoded on a background isolate, so parsing a
///   500 KB blob no longer blocks the main isolate and drops frames.
class JsonLoader {
  /// Payloads at least this large are decoded off the main isolate. Below it
  /// the isolate hand-off costs more than the decode itself.
  static const int _isolateThresholdChars = 32 * 1024;

  static final Map<String, Future<dynamic>> _cache = <String, Future<dynamic>>{};

  static Future<dynamic> load(String assetPath) =>
      _cache[assetPath] ??= _load(assetPath);

  static Future<dynamic> _load(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      if (raw.length >= _isolateThresholdChars) {
        return await compute(
          _decodeJson,
          raw,
          debugLabel: 'JsonLoader.decode $assetPath',
        );
      }
      return _decodeJson(raw);
    } catch (_) {
      // Never cache a failure: let the next caller retry.
      _cache.remove(assetPath);
      rethrow;
    }
  }

  /// Drops the cached raw JSON for [assetPath].
  ///
  /// Repositories call this once they have turned the raw maps into model
  /// objects that they cache themselves, so the app does not keep two
  /// representations of the same megabyte of data alive for the whole
  /// session. Only safe when the caller is the sole consumer of the asset.
  static void evict(String assetPath) {
    _cache.remove(assetPath);
  }
}
