import '../../shared/json_loader.dart';

import 'courtyard_facilities.dart';

/// The three scenes the Courtyard page shows.
///
/// The concert and pet-yard shards use exactly the courtyard's shape — same
/// keys, same groups-and-series layout — and are reached from the courtyard in
/// the game. They were loaded by FacilitiesRepository (so global search found
/// them) but no page rendered them and no category counted them, leaving 535
/// facilities that could be searched for and then never ticked off.
enum CourtyardScene { courtyard, concert, pets }

extension CourtyardSceneLabel on CourtyardScene {
  String get label => switch (this) {
        CourtyardScene.courtyard => 'Courtyard',
        CourtyardScene.concert => 'Concert',
        CourtyardScene.pets => 'Pet Yard',
      };
}

class CourtyardRepository {
  CourtyardRepository._();

  static final CourtyardRepository instance = CourtyardRepository._();

  static const Map<CourtyardScene, String> _assets = <CourtyardScene, String>{
    CourtyardScene.courtyard:
        'assets/data/facilities_jsons/courtyard_facilities.json',
    CourtyardScene.concert:
        'assets/data/facilities_jsons/concert_facilities.json',
    CourtyardScene.pets: 'assets/data/facilities_jsons/pets_facilities.json',
  };

  bool _loaded = false;
  final Map<CourtyardScene, List<CourtyardFacility>> _byScene =
      <CourtyardScene, List<CourtyardFacility>>{};

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
  final Map<CourtyardScene, List<String>> _availableGroups = {};
  final Map<CourtyardScene, List<String>> _allSeriesSorted = {};
  final Map<String, List<CourtyardFacility>> _byGroupAndSeries = {};

  /// Call this once (the page will use a FutureBuilder) to make sure
  /// the JSON is loaded.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      // Routed through JsonLoader so these decodes are shared with
      // FacilitiesRepository, which reads the same shards, and so they happen
      // off the main isolate.
      final all = <CourtyardFacility>[];
      for (final entry in _assets.entries) {
        final data = await JsonLoader.load(entry.value) as List<dynamic>;
        final rows = data
            .map((e) => CourtyardFacility.fromJson(e as Map<String, dynamic>))
            .toList();
        _byScene[entry.key] = rows;
        all.addAll(rows);
      }
      _facilities = all;

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
  ///
  /// Every name here must match a `group` value in
  /// courtyard_facilities.json exactly. Four of them used to be near
  /// misses -- 'Short Fence' vs 'Short Fences', 'Wall Decor' vs
  /// 'Decor (Wall)', 'Floor Decor' vs 'Decor (Floor)' -- and
  /// [availableGroups] silently drops any name the data does not
  /// contain, so 808 of the 1,336 courtyard facilities had no tab and
  /// could never be checked off. The bug hid because each near-miss
  /// name does exist on exactly 2 rows, so the tabs looked populated.
  /// Both spellings are listed so neither set is lost.
  static const List<String> orderedGroups = [
    'Friends Board',
    'Speaker',
    'Game Machine',
    'House Type',
    'Door',
    'Window',
    'Table',
    'Gathering Long Table',
    'Stool',
    'Short Fences',
    'Short Fence',
    'Long Fences',
    'Long Fence',
    'Decor (Wall)',
    'Wall Decor',
    'Plants',
    'Table Decor',
    'Carpet',
    'Decor (Floor)',
    'Floor Decor',
    'Certificate of Honor',
    'Pet Houses',
    'Pet Paradise',
  ];

  /// Every facility in one scene.
  List<CourtyardFacility> facilitiesFor(CourtyardScene scene) =>
      _byScene[scene] ?? const <CourtyardFacility>[];

  /// The group tabs for one scene.
  ///
  /// [orderedGroups] gives the courtyard its curated order; any group the
  /// curated list does not name is appended in data order rather than dropped.
  /// That is the safety net the old version lacked — it filtered the data
  /// through the list and silently lost whatever the list misspelled. Concert
  /// and the pet yard have no curated order, so they come out in data order,
  /// which is wiki order, which is the order the game lists them in.
  List<String> availableGroups([
    CourtyardScene scene = CourtyardScene.courtyard,
  ]) {
    final cached = _availableGroups[scene];
    if (cached != null) return cached;

    final inData = <String>[];
    for (final f in facilitiesFor(scene)) {
      if (!inData.contains(f.group)) inData.add(f.group);
    }

    final curated = scene == CourtyardScene.courtyard
        ? orderedGroups.where(inData.contains).toList()
        : <String>[];
    final out = <String>[
      ...curated,
      ...inData.where((g) => !curated.contains(g)),
    ];

    if (_loaded) _availableGroups[scene] = out;
    return out;
  }

  /// Unique list of series (themes) in one scene, sorted alphabetically.
  List<String> allSeriesSorted([
    CourtyardScene scene = CourtyardScene.courtyard,
  ]) {
    final cached = _allSeriesSorted[scene];
    if (cached != null) return cached;

    final set = <String>{};

    for (final f in facilitiesFor(scene)) {
      final s = f.series;
      if (s != null && s.isNotEmpty) {
        set.add(s);
      }
    }

    final out = set.toList()..sort();
    if (_loaded) _allSeriesSorted[scene] = out;
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
    CourtyardScene scene = CourtyardScene.courtyard,
  }) {
    final key = '${scene.name}\u0000$group\u0000${series ?? ''}';
    final cached = _byGroupAndSeries[key];
    if (cached != null) return cached;

    final out = facilitiesFor(scene).where((f) {
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
