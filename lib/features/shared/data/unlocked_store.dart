// lib/features/shared/data/unlocked_store.dart
//
// Persistent progress store for unlocks/purchases/collections.
//
// Supports multiple “types” of progress buckets, each storing a set of string
// IDs in SharedPreferences. Examples used in this app:
//
//  - 'customer'            → unlocked customers
//  - 'dish'                → unlocked dishes
//  - 'letter'              → unlocked letters
//  - 'facility_purchased'  → purchased facilities
//  - 'recipe_purchased'    → purchased recipes
//  - 'memento_collected'   → collected mementos (customer gifts, posters, etc.)
//
// Usage:
//   await UnlockedStore.instance.init();
//   final unlocked = UnlockedStore.instance.isUnlocked('letter', letterId);
//   await UnlockedStore.instance.setUnlocked('memento_collected', key, true);
//   await UnlockedStore.instance.toggle('facility_purchased', facilityId);
//
// Notes:
// - Safe to call methods before init completes; reads fall back to false,
//   writes will auto-init.
// - You can register additional custom types at runtime via registerType().

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnlockedStore extends ChangeNotifier {
  UnlockedStore._();
  static final UnlockedStore instance = UnlockedStore._();

  // Default progress buckets used by the app.
  static const List<String> _defaultTypes = <String>[
    'customer',
    'dish',
    'letter',
    'facility_purchased',
    'recipe_purchased',
    'memento_collected',
  ];

  final Map<String, Set<String>> _sets = <String, Set<String>>{};
  bool _inited = false;
  Future<void>? _initFuture;

  /// Returns true once data has been read from SharedPreferences.
  bool get isInitialized => _inited;

  /// Initialize the store and preload the known types.
  /// You may pass extraTypes to add additional buckets on startup.
  Future<void> init({List<String> extraTypes = const []}) {
    _initFuture ??= _doInit(extraTypes: extraTypes);
    return _initFuture!;
  }

  Future<void> _doInit({required List<String> extraTypes}) async {
    final prefs = await SharedPreferences.getInstance();
    final types = <String>{..._defaultTypes, ...extraTypes};
    for (final type in types) {
      _sets[type] =
          (prefs.getStringList(_prefsKey(type)) ?? const <String>[])
              .toSet();
    }
    _inited = true;
    notifyListeners();
  }

  /// Ensure a bucket exists and is loaded (useful for late-added custom types).
  Future<void> registerType(String type) async {
    if (_sets.containsKey(type)) return;
    final prefs = await SharedPreferences.getInstance();
    _sets[type] =
        (prefs.getStringList(_prefsKey(type)) ?? const <String>[]).toSet();
    // Do not flip _inited here; this can be called before/after init.
    notifyListeners();
  }

  /// Read-only view of IDs in a given bucket.
  Set<String> ids(String type) {
    return Set<String>.unmodifiable(_sets[type] ?? const <String>{});
  }

  /// Check whether an ID is marked in the given bucket.
  /// Returns false until init completes (then real state).
  bool isUnlocked(String type, String id) {
    final set = _sets[type];
    if (set == null) return false;
    return set.contains(id);
  }

  /// Mark/unmark an ID in the given bucket and persist to disk.
  Future<void> setUnlocked(String type, String id, bool value) async {
    if (!_inited) {
      // Ensure the store is ready before writing.
      await init();
    }
    // Make sure the bucket exists.
    _sets[type] ??= <String>{};

    final set = _sets[type]!;
    final changed = value ? set.add(id) : set.remove(id);
    if (!changed) return; // No-op.

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(type), set.toList());
    notifyListeners();
  }

  /// Convenience: toggle the state for an ID within a bucket.
  Future<void> toggle(String type, String id) async {
    await setUnlocked(type, id, !isUnlocked(type, id));
  }

  /// Number of IDs marked in a bucket.
  int count(String type) => _sets[type]?.length ?? 0;

  /// Clear a single bucket (does not remove the bucket itself).
  Future<void> clearType(String type) async {
    if (!_inited) {
      await init();
    }
    _sets[type] = <String>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(type), const <String>[]);
    notifyListeners();
  }

  /// Wipe all buckets managed by this store.
  Future<void> clearAll() async {
    if (!_inited) {
      await init();
    }
    final prefs = await SharedPreferences.getInstance();
    for (final type in _sets.keys) {
      _sets[type] = <String>{};
      await prefs.setStringList(_prefsKey(type), const <String>[]);
    }
    notifyListeners();
  }

  /// Export a snapshot for backup or debugging.
  Map<String, List<String>> exportSnapshot() {
    return _sets.map((k, v) => MapEntry(k, v.toList()));
  }

  String _prefsKey(String type) => 'unlocked:$type';
}
