// lib/features/shared/data/unlocked_store.dart
//
// Persistent progress store for unlocks/purchases/collections.
//
// Local storage uses SharedPreferences.
// - Signed out: uses the "guest" namespace (local-only)
// - Signed in: uses the user's uid namespace (local + Firestore sync)
//
// Firestore document: users/{uid}
//   { unlocked: {type: [ids...]}, unlockedUpdatedAt: serverTimestamp }
//
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnlockedStore extends ChangeNotifier {
  UnlockedStore._();
  static final UnlockedStore instance = UnlockedStore._();

  /// Buckets loaded from storage as soon as the app starts.
  ///
  /// Anything NOT listed here has to be `registerType`d before its saved ids
  /// can be read back, and until that happens `isUnlocked` answers false and
  /// the next `setUnlocked` writes a fresh set over the saved one. Several
  /// buckets were missing and silently lost progress across restarts, so every
  /// bucket the app actually writes is listed now. Keep this in sync with
  /// `ProgressTypes` in lib/features/completion/data/progress_types.dart.
  static const List<String> _defaultTypes = <String>[
    // Original defaults. 'customer', 'facility_purchased' and
    // 'recipe_purchased' are legacy spellings kept so old saves still load.
    'customer',
    'dish',
    'letter',
    'facility_purchased',
    'recipe_purchased',
    'memento_collected',

    // Buckets the pages actually read and write.
    'customers',
    'facility',
    'courtyard_facility_purchased',
    'poster',
    'movie_act',
    'acorn',
    'pet_owned',
    'pet_mature',
    'pet_room_unlocked',
    'pet_photo_task_done',
    'staff_unlocked',
    'battle_pass_claimed',
    'battle_pass_premium',
  ];

  final Map<String, Set<String>> _sets = <String, Set<String>>{};
  bool _inited = false;
  Future<void>? _initFuture;

  User? _user;

  // Namespace for SharedPreferences keys.
  // - "guest" when signed out
  // - uid when signed in
  static const String _guestNs = 'guest';
  String _ns = _guestNs;

  bool _cloudSyncInProgress = false;
  Timer? _debounceUpload;
  static const Duration _uploadDebounce = Duration(milliseconds: 600);

  bool get isInitialized => _inited;

  /// The buckets loaded from storage on startup.
  ///
  /// Exposed so a test can assert that every bucket the app writes is listed
  /// here. A bucket missing from this list is not read back after a relaunch,
  /// which is how real tracked progress was silently lost before.
  @visibleForTesting
  static List<String> get startupBuckets =>
      List<String>.unmodifiable(_defaultTypes);

  /// Drops all in-memory state so the next [init] re-reads SharedPreferences.
  ///
  /// Test-only. This is the only way to exercise the "force-quit and relaunch"
  /// path, because [init] memoises its future and the store is a singleton.
  /// It deliberately does NOT touch SharedPreferences, so a test can write
  /// ids, reset, re-init and assert the ids came back from storage.
  @visibleForTesting
  void debugResetForTest() {
    _debounceUpload?.cancel();
    _debounceUpload = null;
    _sets.clear();
    _inited = false;
    _initFuture = null;
    _user = null;
    _ns = 'guest';
    _cloudSyncInProgress = false;
  }

  String get activeNamespace => _ns;

  Future<void> init({List<String> extraTypes = const []}) {
    _initFuture ??= _doInit(extraTypes: extraTypes);
    return _initFuture!;
  }

  Future<void> _doInit({required List<String> extraTypes}) async {
    // Load current namespace (guest by default, unless attachUser happened first).
    final types = <String>{..._defaultTypes, ...extraTypes};
    await _loadNamespaceFromPrefs(types);

    _inited = true;
    notifyListeners();

    // If already signed in by the time init finishes, sync.
    if (_user != null) {
      unawaited(_syncOnSignIn());
    }
  }

  // Called by AuthBinder on auth changes.
  void attachUser(User? user) {
    final nextNs = user?.uid ?? 'guest';
    final prevNs = _ns;

    _user = user;

    if (prevNs == nextNs) {
      // Same profile, nothing to switch.
      return;
    }

    _ns = nextNs;

    // Stop any pending uploads when switching profiles.
    _debounceUpload?.cancel();
    _debounceUpload = null;

    // Switch local state immediately so UI resets.
    if (_inited) {
      unawaited(_switchProfileAndNotify());
    } else {
      // init() will read the correct namespace later
    }
  }

  Future<void> _switchProfileAndNotify() async {
    final types = <String>{..._defaultTypes, ..._sets.keys};
    await _loadNamespaceFromPrefs(types);
    await adoptGuestProgressIfEmpty();

    notifyListeners();

    // If switching into a signed-in profile, perform cloud sync.
    if (_user != null) {
      unawaited(_syncOnSignIn());
    }
  }

  Future<void> _loadNamespaceFromPrefs(Set<String> types) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear in-memory sets so UI resets on profile switch.
    _sets.clear();

    for (final type in types) {
      _sets[type] =
          (prefs.getStringList(_prefsKey(type)) ?? const <String>[]).toSet();
    }
  }

  Future<void> registerType(String type) async {
    if (_sets.containsKey(type)) return;

    final prefs = await SharedPreferences.getInstance();
    _sets[type] =
        (prefs.getStringList(_prefsKey(type)) ?? const <String>[]).toSet();

    notifyListeners();

    // If signed in, push this bucket (debounced).
    _scheduleUpload();
  }

  Set<String> ids(String type) {
    return Set<String>.unmodifiable(_sets[type] ?? const <String>{});
  }

  bool isUnlocked(String type, String id) {
    final set = _sets[type];
    if (set == null) return false;
    return set.contains(id);
  }

  Future<void> setUnlocked(String type, String id, bool value) async {
    if (!_inited) {
      await init();
    }

    _sets[type] ??= <String>{};
    final set = _sets[type]!;
    final changed = value ? set.add(id) : set.remove(id);
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(type), set.toList());
    await _bumpLocalUpdatedAt(prefs);

    notifyListeners();
    _scheduleUpload();
  }

  Future<void> toggle(String type, String id) async {
    await setUnlocked(type, id, !isUnlocked(type, id));
  }

  /// Set many ids at once (used by "Check all" / "Uncheck all" on a segment).
  /// Persists and notifies a single time instead of once per id.
  Future<void> setManyUnlocked(
      String type, Iterable<String> ids, bool value) async {
    if (!_inited) {
      await init();
    }
    _sets[type] ??= <String>{};
    final set = _sets[type]!;
    var changed = false;
    for (final id in ids) {
      final c = value ? set.add(id) : set.remove(id);
      changed = changed || c;
    }
    if (!changed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(type), set.toList());
    await _bumpLocalUpdatedAt(prefs);

    notifyListeners();
    _scheduleUpload();
  }

  int count(String type) => _sets[type]?.length ?? 0;

  Future<void> clearType(String type) async {
    if (!_inited) {
      await init();
    }
    _sets[type] = <String>{};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(type), const <String>[]);
    await _bumpLocalUpdatedAt(prefs);

    notifyListeners();
    _scheduleUpload();
  }

  Future<void> clearAll() async {
    if (!_inited) {
      await init();
    }
    final prefs = await SharedPreferences.getInstance();
    for (final type in _sets.keys) {
      _sets[type] = <String>{};
      await prefs.setStringList(_prefsKey(type), const <String>[]);
    }
    await _bumpLocalUpdatedAt(prefs);

    notifyListeners();
    _scheduleUpload();
  }

  Map<String, List<String>> exportSnapshot() {
    return _sets.map((k, v) => MapEntry(k, v.toList()));
  }

  Future<void> syncNow() async {
    if (_user == null) return;
    if (!_inited) await init();
    await _uploadToCloud();
  }

  // ------------------------
  // Per-namespace timestamps
  // ------------------------

  String get _prefsLocalUpdatedAtKey => 'unlocked:${_ns}:_localUpdatedAtMs';
  String get _prefsLastCloudPullAtKey => 'unlocked:${_ns}:_lastCloudPullAtMs';

  Future<void> _bumpLocalUpdatedAt(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_prefsLocalUpdatedAtKey, now);
  }

  Future<int> _localUpdatedAtMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsLocalUpdatedAtKey) ?? 0;
  }

  Future<void> _setLastCloudPullAtMs(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsLastCloudPullAtKey, ms);
  }

  Future<int> _lastCloudPullAtMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsLastCloudPullAtKey) ?? 0;
  }

  // ------------------------
  // Cloud sync
  // ------------------------

  DocumentReference<Map<String, dynamic>> _docForUser(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  void _scheduleUpload() {
    if (_user == null) return; // guest mode: local only
    if (_cloudSyncInProgress) return;

    _debounceUpload?.cancel();
    _debounceUpload = Timer(_uploadDebounce, () {
      unawaited(_uploadToCloud());
    });
  }

  Future<void> _syncOnSignIn() async {
    if (_cloudSyncInProgress) return;
    if (_user == null) return;

    if (!_inited) {
      await init();
    }

    _cloudSyncInProgress = true;
    try {
      final uid = _user!.uid;
      final docRef = _docForUser(uid);
      final snap = await docRef.get();

      final localUpdatedAt = await _localUpdatedAtMs();
      final lastCloudPullAt = await _lastCloudPullAtMs();

      if (!snap.exists) {
        await _uploadToCloud();
        await _setLastCloudPullAtMs(DateTime.now().millisecondsSinceEpoch);
        return;
      }

      final data = snap.data();
      final cloudUpdatedAtMs = _readCloudUpdatedAtMs(data);

      final cloudHasNewer = cloudUpdatedAtMs > localUpdatedAt;
      final wePulledRecently =
          lastCloudPullAt >= cloudUpdatedAtMs && cloudUpdatedAtMs != 0;

      if (cloudHasNewer && !wePulledRecently) {
        final cloudSets = _readCloudProgress(data);
        await _applyCloudSnapshotToLocal(cloudSets);
        await _setLastCloudPullAtMs(DateTime.now().millisecondsSinceEpoch);
        notifyListeners();
      } else {
        await _uploadToCloud();
        await _setLastCloudPullAtMs(DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {
      // Keep working locally if cloud fails.
    } finally {
      _cloudSyncInProgress = false;
    }
  }

  int _readCloudUpdatedAtMs(Map<String, dynamic>? data) {
    if (data == null) return 0;
    final updatedAt = data['unlockedUpdatedAt'];
    if (updatedAt is Timestamp) return updatedAt.millisecondsSinceEpoch;
    if (updatedAt is int) return updatedAt;
    return 0;
  }

  Map<String, List<String>> _readCloudProgress(Map<String, dynamic>? data) {
    if (data == null) return {};
    final raw = data['unlocked'] as Map<String, dynamic>?;
    if (raw == null) return {};

    final out = <String, List<String>>{};
    for (final entry in raw.entries) {
      final v = entry.value;
      if (v is List) {
        out[entry.key] = v.map((e) => e.toString()).toList();
      }
    }
    return out;
  }

  Future<void> _applyCloudSnapshotToLocal(Map<String, List<String>> cloud) async {
    final prefs = await SharedPreferences.getInstance();

    // Overwrite the active namespace (uid) from cloud.
    for (final entry in cloud.entries) {
      final type = entry.key;
      final ids = entry.value.toSet();
      _sets[type] = ids;
      await prefs.setStringList(_prefsKey(type), ids.toList());
    }

    // Ensure defaults exist.
    for (final t in _defaultTypes) {
      _sets[t] ??= <String>{};
      await prefs.setStringList(_prefsKey(t), _sets[t]!.toList());
    }

    await _bumpLocalUpdatedAt(prefs);
  }

  Future<void> _uploadToCloud() async {
    if (_user == null) return;
    if (!_inited) await init();

    _cloudSyncInProgress = true;
    try {
      final uid = _user!.uid;

      final snapshot = exportSnapshot();
      final docRef = _docForUser(uid);

      await docRef.set(
        <String, dynamic>{
          'unlocked': snapshot,
          'unlockedUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final prefs = await SharedPreferences.getInstance();
      await _bumpLocalUpdatedAt(prefs);
    } catch (_) {
      // swallow
    } finally {
      _cloudSyncInProgress = false;
    }
  }

  /// Switches profile the way signing in does, without a Firebase user.
  ///
  /// `attachUser` takes a `User`, which cannot be constructed in a unit test,
  /// and the namespace switch is where progress was being lost — so it needs
  /// a seam of its own.
  @visibleForTesting
  Future<void> debugSwitchNamespace(String ns) async {
    _ns = ns;
    await _switchProfileAndNotify();
  }

  /// Carries guest progress into an account the first time it signs in.
  ///
  /// Progress is namespaced per profile (`unlocked:<ns>:<type>`) and signing
  /// in switches the namespace to the Firebase uid. Nothing copied the old
  /// namespace across, so someone who had tracked months of progress as a
  /// guest — which is the normal way to use this app, since `main.dart`
  /// launches straight into it — tapped Login and saw zero. Worse, the cloud
  /// document does not exist yet for a new account, so `_syncOnSignIn` would
  /// then upload that empty state as the account's starting point.
  ///
  /// Runs only when the account's own namespace is empty, so it can never
  /// overwrite progress an account already has. The guest keys are left in
  /// place rather than moved, so signing out still finds them.
  ///
  /// Returns how many ids were adopted.
  @visibleForTesting
  Future<int> adoptGuestProgressIfEmpty() async {
    if (_ns == _guestNs) return 0;
    if (_sets.values.any((ids) => ids.isNotEmpty)) return 0;

    final prefs = await SharedPreferences.getInstance();
    const prefix = 'unlocked:$_guestNs:';

    var adopted = 0;
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith(prefix)) continue;

      final type = key.substring(prefix.length);
      // The namespace also holds bookkeeping under the same prefix —
      // `_localUpdatedAtMs` and `_lastCloudPullAtMs` are ints, and asking
      // for them as a string list throws. Buckets never start with '_'.
      if (type.startsWith('_')) continue;

      final ids = prefs.getStringList(key) ?? const <String>[];
      if (ids.isEmpty) continue;
      await prefs.setStringList(_prefsKey(type), ids);
      _sets[type] = ids.toSet();
      adopted += ids.length;
    }

    if (adopted > 0) {
      // So the first cloud sync treats the adopted progress as the newer
      // side rather than overwriting it with an empty document.
      await _bumpLocalUpdatedAt(prefs);
    }
    return adopted;
  }

  String _prefsKey(String type) => 'unlocked:${_ns}:$type';
}
