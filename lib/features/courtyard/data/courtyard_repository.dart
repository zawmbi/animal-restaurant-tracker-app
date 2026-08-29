import '../../shared/json_loader.dart';

import 'courtyard_facilities.dart';

class CourtyardRepository {
  CourtyardRepository._();

  static final CourtyardRepository instance = CourtyardRepository._();

  static const String _asset =
      'assets/data/facilities_jsons/courtyard_facilities.json';

  bool _loaded = false;
  List<CourtyardFacility> _facilities = [];

  /// Cached *future*, so a second `ensureLoaded()` that arrives while the
  /// first is still in flight waits on it instead of kicking off a second
  /// load + decode of this 512 KB shard.
  Future<void>? _loadFuture;

  // ---- memoised derived views -------------------------------------------
  //
  // `_facilities` never changes after the single load, so everything derived
  // from it can be computed once. The Courtyard page calls all three of these
  // from `build()`, which runs again on every checkbox tap; without memoising,
  // one tap costs three full passes over 1336 facilities plus two sorts.
  List<CourtyardFacility>? _allFacilitiesView;
  List<String>? _availableGroups;
  List<String>? _allSeriesSorted;
  final Map<String, List<CourtyardFacility>> _byGroupAndSeries = {};

  /// Call this once (the page will use a FutureBuilder) to make sure
  /// the JSON is loaded.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      // Routed through JsonLoader so this decode is shared with
      // FacilitiesRepository, which reads the same shard for
      // FacilityArea.courtyard, and so it happens off the main isolate.
      final data = await JsonLoader.load(_asset) as List<dynamic>;

      _facilities = data
          .map((e) => CourtyardFacility.fromJson(e as Map<String, dynamic>))
          .toList();

      _loaded = true;
    } catch (_) {
      _loadFuture = null; // allow a retry
      rethrow;
    }
  }

  bool get isLoaded => _loaded;

  List<CourtyardFacility> get allFacilities {
    // Only memoise once the data is in, so an early call can never freeze an
    // empty view into the cache.
    if (!_loaded) return List.unmodifiable(_facilities);
    return _allFacilitiesView ??= List.unmodifiable(_facilities);
  }

  /// All groups we care about on the Courtyard page (top tabs),
  /// in a fixed order to match your screenshot + Pet Houses / Pet Paradise.
  static const List<String> orderedGroups = [
    'Friends Board',
    'Speaker',
    'Game Machine',
    'House Type',
    'Door',
    'Window',
    'Table',
    'Stool',
    'Short Fence',
    'Long Fence',
    'Wall Decor',
    'Plants',
    'Table Decor',
    'Carpet',
    'Floor Decor',
    'Certificate of Honor',
    'Pet Houses',
    'Pet Paradise',
  ];

  /// Groups actually present in the JSON, in the same order as [orderedGroups].
  List<String> availableGroups() {
    final cached = _availableGroups;
    if (cached != null) return cached;

    final existing = <String>{
      for (final f in _facilities) f.group,
    };
    final out = orderedGroups.where(existing.contains).toList();
    if (_loaded) _availableGroups = out;
    return out;
  }

  /// Unique list of series (themes) sorted alphabetically.
  List<String> allSeriesSorted() {
    final cached = _allSeriesSorted;
    if (cached != null) return cached;

    final set = <String>{};

    for (final f in _facilities) {
      final s = f.series;
      if (s != null && s.isNotEmpty) {
        set.add(s);
      }
    }

    final out = set.toList()..sort();
    if (_loaded) _allSeriesSorted = out;
    return out;
  }

  /// Facilities filtered by group and optional series.
  ///
  /// Memoised per (group, series): the result depends only on the immutable
  /// loaded data, so repeated builds reuse the same filtered + sorted list
  /// instead of re-scanning and re-sorting 1336 facilities.
  List<CourtyardFacility> byGroupAndSeries(
    String group, {
    String? series,
  }) {
    final key = '$group\u0000${series ?? ''}';
    final cached = _byGroupAndSeries[key];
    if (cached != null) return cached;

    final out = _facilities.where((f) {
      if (f.group != group) return false;
      if (series != null && series.isNotEmpty && series != 'All') {
        return f.series == series;
      }
      return true;
    }).toList();
    // Source order = wiki order = the order the game lists them in.

    if (_loaded) _byGroupAndSeries[key] = out;
    return out;
  }

  // ----------------- summary helpers -------------------------

  /// Minimum FILM income from a set of facilities.
  /// Looks for effects like:
  /// { "type": "incomePerMinute", "currency": "film", "amount": 5 }
  int minFilmIncome(Iterable<CourtyardFacility> facilities) {
    var total = 0;
    for (final f in facilities) {
      for (final e in f.effects) {
        if (e.type == 'incomePerMinute' && e.currency == 'film') {
          total += (e.amount ?? 0).round();
        }
      }
    }
    return total;
  }

  /// Minimum COD income from a set of facilities.
  int minCodIncome(Iterable<CourtyardFacility> facilities) {
    var total = 0;
    for (final f in facilities) {
      for (final e in f.effects) {
        if (e.type == 'incomePerMinute' && e.currency == 'cod') {
          total += (e.amount ?? 0).round();
        }
      }
    }
    return total;
  }

  /// Rating bonus from facilities, using effects like:
  /// { "type": "ratingBonus", "amount": 3 }
  double totalRating(Iterable<CourtyardFacility> facilities) {
    var total = 0.0;
    for (final f in facilities) {
      for (final e in f.effects) {
        if (e.type == 'ratingBonus') {
          total += (e.amount ?? 0).toDouble();
        }
      }
    }
    return total;
  }

  /// Friend limit, using effects like:
  /// { "type": "friendLimitIncrease", "friendSlots": 5 }
  int friendLimit(
    Iterable<CourtyardFacility> facilities, {
    int baseSlots = 10,
  }) {
    var limit = baseSlots;
    for (final f in facilities) {
      for (final e in f.effects) {
        if (e.type == 'friendLimitIncrease') {
          limit += e.friendSlots ?? 0;
        }
      }
    }
    return limit;
  }
}
