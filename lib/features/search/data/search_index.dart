// ignore_for_file: unused_import

import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart'
    as facrepo;

import '../../customers/data/customers_repository.dart';
import '../../customers/model/customer.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../completion/data/progress_types.dart';
import '../../facilities/model/facility.dart';
import '../../mementos/data/mementos_index.dart';

enum HitType { customer, letter, dish, facility, memento, battlePass }

class SearchHit {
  final HitType type;
  final String id;         // main id
  final String title;
  final String? subtitle;  // optional (e.g., customer name for a memento)
  final String? key;       // for mementos we store the composite key

  /// The progress bucket this hit's checkbox reads and writes, when the type
  /// alone does not settle it. Facilities are split across two buckets by
  /// area, so the row cannot infer it from [type].
  final String? bucket;

  /// How well this hit matched the query. Higher is better; results come back
  /// sorted by it. Only meaningful relative to other hits for the same query.
  final int score;

  const SearchHit(this.type, this.id, this.title,
      {this.subtitle, this.key, this.bucket, this.score = 0});
}

// ---------------------------------------------------------------------------
// Relevance.
//
// Matching used to be `contains` over a flat list of strings, with results
// ordered by type and then alphabetically. That had two consequences a user
// notices immediately: typing an entity's exact name did not put it first
// (searching 'deer' listed every memento whose flavour text says "deer"
// above the customer called Deer), and a multi-word query only matched a
// literal substring, so 'white bun' found nothing at all.
//
// Now every indexed string carries a weight, each query word is scored
// against every string, and a row must match all the words to appear.
// ---------------------------------------------------------------------------

/// The entity's own name. What the user is almost always typing.
const int _wName = 3;

/// Supporting identity: tags, a letter's series, a dish's section, the
/// customer a memento belongs to, the area a facility sits in. Worth
/// matching, not worth outranking a name.
const int _wTag = 2;

/// Free text, i.e. memento descriptions. 1,182 mementos carry a sentence of
/// flavour text apiece, so this is the largest and least specific surface in
/// the app. It should find things nothing else can, and never crowd out a
/// name match.
const int _wText = 1;

final RegExp _whitespace = RegExp(r'\s+');

class _Key {
  final String text; // pre-lowered at index time
  final int weight;
  const _Key(this.text, this.weight);
}

bool _isWordBreak(int codeUnit) {
  // Text is already lower-cased, so letters are a-z only.
  final isLetter = codeUnit >= 0x61 && codeUnit <= 0x7A;
  final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
  return !isLetter && !isDigit;
}

/// How well one indexed string matches one query word, before weighting.
///
/// The ladder is deliberate: an exact name beats a name that starts with the
/// word, which beats the word appearing as its own word, which beats the word
/// buried mid-word. 'bun' should rank "Bunny" over "Sugar Bun Bunny" over
/// "Blueberry Bundt".
int _wordScore(String text, String word) {
  if (text == word) return 100;
  if (text.startsWith(word)) return 80;
  final i = text.indexOf(word);
  if (i < 0) return 0;
  return _isWordBreak(text.codeUnitAt(i - 1)) ? 60 : 40;
}

/// Total score for a row, or 0 if it should not appear at all.
///
/// Every query word has to land somewhere on the row — that is what makes
/// 'white bun' and 'bun white' both find White Bunny while 'white truck'
/// finds neither. Each word scores against its best field, so a row matching
/// both words in its name outranks one matching one word in its name and the
/// other in a description.
int _scoreRow(List<_Key> keys, List<String> words, String query) {
  var total = 0;
  for (var w = 0; w < words.length; w++) {
    var best = 0;
    for (var k = 0; k < keys.length; k++) {
      final s = _wordScore(keys[k].text, words[w]) * keys[k].weight;
      if (s > best) best = s;
    }
    if (best == 0) return 0;
    total += best;
  }

  // Typing a name in full should put that entity at the top, whatever else
  // mentions it. Without this, 'deer' scores the customer Deer the same as a
  // memento called 'Deer Antlers', and alphabetical order decides.
  if (keys.isNotEmpty && keys[0].weight == _wName) {
    final name = keys[0].text;
    if (name == query) {
      total += 1000;
    } else if (name.startsWith(query)) {
      total += 300;
    }
  }

  return total;
}

/// Which screen a facility hit belongs to, so two facilities that share a
/// display name ('Christmas Tree' is both a restaurant plant and a courtyard
/// one) can be told apart in the results.
String _areaLabel(FacilityArea area) => switch (area) {
      FacilityArea.restaurant => 'Restaurant',
      FacilityArea.kitchen => 'Kitchen',
      FacilityArea.garden => 'Garden',
      FacilityArea.buffet => 'Buffet',
      FacilityArea.takeout => 'Takeout',
      FacilityArea.terrace => 'Terrace',
      FacilityArea.courtyard => 'Courtyard',
      FacilityArea.courtyard_concert => 'Concert',
      FacilityArea.courtyard_pets => 'Pet Yard',
    };

// ---------------------------------------------------------------------------
// Indexed rows.
//
// The search text for each entity is lower-cased once, at preload time, rather
// than on every keystroke. Matching walks pre-computed haystacks and allocates
// nothing but the split query.
// ---------------------------------------------------------------------------

class _CustomerRow {
  final Customer customer;
  final List<_Key> keys;
  const _CustomerRow(this.customer, this.keys);
}

class _LetterRow {
  final Letter letter;
  final List<_Key> keys;
  const _LetterRow(this.letter, this.keys);
}

class _DishRow {
  final Dish dish;
  final String? inferred; // friendly category label, shown as the subtitle
  final List<_Key> keys;
  const _DishRow(this.dish, this.inferred, this.keys);
}

class _FacilityRow {
  final Facility facility;
  final List<_Key> keys;
  const _FacilityRow(this.facility, this.keys);
}

class _MementoRow {
  final MementoEntry memento;
  final List<_Key> keys;
  const _MementoRow(this.memento, this.keys);
}

class SearchIndex {
  SearchIndex._();
  static final SearchIndex instance = SearchIndex._();

  List<_CustomerRow>? _customers;
  List<_LetterRow>? _letters;
  List<_DishRow>? _dishes;
  List<_FacilityRow>? _facilities;
  List<_MementoRow>? _mementos;

  /// Single-flight: the home page kicks off `preload()` from `initState`, and
  /// a search issued while that is still running now waits on the same future
  /// instead of starting a second set of loads and parses.
  Future<void>? _preloadFuture;

  Future<void> preload() => _preloadFuture ??= _build();

  Future<void> _build() async {
    try {
      _customers ??= _indexCustomers(await CustomersRepository.instance.all());
      _letters ??= _indexLetters(await LettersRepository.instance.all());
    } catch (_) {
      _preloadFuture = null; // required sections failed; allow a retry
      rethrow;
    }

    // Optional sections: as before, a failure here must not break search.
    try {
      _dishes ??= _indexDishes(await DishesRepository.instance.all());
    } catch (_) {}
    try {
      _facilities ??=
          _indexFacilities(await facrepo.FacilitiesRepository.instance.all());
    } catch (_) {}
    try {
      // Built once here instead of per keystroke. `MementosIndex.all()` has no
      // cache of its own: it re-reads both memento assets, rebuilds a
      // customer-id map over 564 customers and re-allocates every
      // `MementoEntry` on each call, so calling it per keystroke was by far
      // the most expensive part of a search.
      _mementos ??= _indexMementos(await MementosIndex.instance.all());
    } catch (_) {}
  }

  static List<_CustomerRow> _indexCustomers(List<Customer> customers) {
    return [
      for (final c in customers)
        _CustomerRow(c, <_Key>[
          _Key(c.name.toLowerCase(), _wName),
          for (final t in c.tags) _Key(t.toLowerCase(), _wTag),
        ]),
    ];
  }

  static List<_LetterRow> _indexLetters(List<Letter> letters) {
    return [
      for (final l in letters)
        _LetterRow(l, <_Key>[
          _Key(l.name.toLowerCase(), _wName),
          if (l.series != null) _Key(l.series!.toLowerCase(), _wTag),
        ]),
    ];
  }

  static List<_DishRow> _indexDishes(List<Dish> dishes) {
    final out = <_DishRow>[];
    for (final d in dishes) {
      final inferred = _inferCategoryLabel(d);
      out.add(_DishRow(d, inferred, <_Key>[
        _Key(d.name.toLowerCase(), _wName),
        for (final s in d.sections) _Key(s.toLowerCase(), _wTag),
        if (inferred != null) _Key(inferred.toLowerCase(), _wTag),
      ]));
    }
    return out;
  }

  static List<_FacilityRow> _indexFacilities(List<Facility> facilities) {
    return [
      for (final f in facilities)
        _FacilityRow(f, <_Key>[
          _Key(f.name.toLowerCase(), _wName),
          // So 'courtyard tree' and 'pet yard bowl' narrow to one scene.
          _Key(_areaLabel(f.area).toLowerCase(), _wTag),
        ]),
    ];
  }

  static List<_MementoRow> _indexMementos(List<MementoEntry> mementos) {
    return [
      for (final m in mementos)
        _MementoRow(m, <_Key>[
          _Key(m.name.toLowerCase(), _wName),
          if (m.customerName != null) _Key(m.customerName!.toLowerCase(), _wTag),
          _Key(m.description.toLowerCase(), _wText),
        ]),
    ];
  }

  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchHit>[];
    final words = q.split(_whitespace)..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return const <SearchHit>[];
    await preload();

    final hits = <SearchHit>[];

    // Customers
    for (final r in _customers ?? const <_CustomerRow>[]) {
      final score = _scoreRow(r.keys, words, q);
      if (score > 0) {
        hits.add(SearchHit(HitType.customer, r.customer.id, r.customer.name,
            score: score));
      }
    }

    // Letters
    for (final r in _letters ?? const <_LetterRow>[]) {
      final score = _scoreRow(r.keys, words, q);
      if (score > 0) {
        hits.add(SearchHit(HitType.letter, r.letter.id, r.letter.name,
            subtitle: r.letter.series, score: score));
      }
    }

    // Dishes (no d.category anymore -> inferred from sections at index time)
    for (final r in _dishes ?? const <_DishRow>[]) {
      final score = _scoreRow(r.keys, words, q);
      if (score > 0) {
        hits.add(SearchHit(HitType.dish, r.dish.id, r.dish.name,
            subtitle: r.inferred, score: score));
      }
    }

    // Facilities
    for (final r in _facilities ?? const <_FacilityRow>[]) {
      final score = _scoreRow(r.keys, words, q);
      if (score > 0) {
        hits.add(SearchHit(
          HitType.facility,
          r.facility.id,
          r.facility.name,
          subtitle: _areaLabel(r.facility.area),
          bucket: ProgressTypes.facilityBucketFor(r.facility.area.name),
          score: score,
        ));
      }
    }

    // Mementos
    for (final r in _mementos ?? const <_MementoRow>[]) {
      final score = _scoreRow(r.keys, words, q);
      if (score > 0) {
        hits.add(SearchHit(
          HitType.memento,
          r.memento.id,
          r.memento.name,
          subtitle: r.memento.customerName,
          key: r.memento.key,
          score: score,
        ));
      }
    }

    // Best match first. Ties break by type (the old order: customers, letters,
    // dishes, facilities, mementos), then by the shorter title, which is the
    // more specific one — 'Bunny' before 'Bunny Statue' — then alphabetically
    // so the order never wobbles between identical queries.
    hits.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      final t = a.type.index.compareTo(b.type.index);
      if (t != 0) return t;
      final l = a.title.length.compareTo(b.title.length);
      if (l != 0) return l;
      return a.title.compareTo(b.title);
    });

    return hits;
  }
}

/// Convert Dish.sections -> friendly category label shown in search results.
String? _inferCategoryLabel(Dish d) {
  final s = d.sections.map((e) => e.trim().toLowerCase()).toSet();
  bool has(String label) => s.contains(label.toLowerCase());
  if (has('freshly made') || has('fresh dishes')) return 'Freshly Made';
  if (has('buffet')) return 'Buffet';
  if (has('takeout')) return 'Takeout';
  if (has('vegetable garden recipes') || has('vegetable garden')) {
    return 'Vegetable Garden Recipes';
  }
  if (has('food truck') || has('food truck recipes')) return 'Food Truck';
  return null;
}
