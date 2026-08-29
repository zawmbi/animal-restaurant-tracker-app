// ignore_for_file: unused_import

import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart'
    as facrepo;

import '../../customers/data/customers_repository.dart';
import '../../customers/model/customer.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../facilities/model/facility.dart';
import '../../mementos/data/mementos_index.dart';

enum HitType { customer, letter, dish, facility, memento, battlePass }

class SearchHit {
  final HitType type;
  final String id;         // main id
  final String title;
  final String? subtitle;  // optional (e.g., customer name for a memento)
  final String? key;       // for mementos we store the composite key
  const SearchHit(this.type, this.id, this.title, {this.subtitle, this.key});
}

// ---------------------------------------------------------------------------
// Indexed rows.
//
// The search text for each entity is lower-cased once, at preload time, rather
// than on every keystroke. `GlobalSearchPage` calls `search()` straight from
// `onChanged` with no debounce, so the old code allocated a fresh lower-case
// String for every name, tag, section and description of every entity on every
// character typed — tens of thousands of short-lived Strings per keystroke.
// Matching now walks pre-computed haystacks and allocates nothing.
// ---------------------------------------------------------------------------

bool _anyContains(List<String> haystacks, String q) {
  for (var i = 0; i < haystacks.length; i++) {
    if (haystacks[i].contains(q)) return true;
  }
  return false;
}

class _CustomerRow {
  final Customer customer;
  final List<String> keys; // name + tags, lower-cased
  const _CustomerRow(this.customer, this.keys);
}

class _LetterRow {
  final Letter letter;
  final List<String> keys; // name + series, lower-cased
  const _LetterRow(this.letter, this.keys);
}

class _DishRow {
  final Dish dish;
  final String? inferred; // friendly category label, shown as the subtitle
  final List<String> keys; // name + sections + inferred label, lower-cased
  const _DishRow(this.dish, this.inferred, this.keys);
}

class _FacilityRow {
  final Facility facility;
  final String nameLower;
  const _FacilityRow(this.facility, this.nameLower);
}

class _MementoRow {
  final MementoEntry memento;
  final List<String> keys; // name + description + customer name, lower-cased
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
        _CustomerRow(c, <String>[
          c.name.toLowerCase(),
          for (final t in c.tags) t.toLowerCase(),
        ]),
    ];
  }

  static List<_LetterRow> _indexLetters(List<Letter> letters) {
    return [
      for (final l in letters)
        _LetterRow(l, <String>[
          l.name.toLowerCase(),
          if (l.series != null) l.series!.toLowerCase(),
        ]),
    ];
  }

  static List<_DishRow> _indexDishes(List<Dish> dishes) {
    final out = <_DishRow>[];
    for (final d in dishes) {
      final inferred = _inferCategoryLabel(d);
      out.add(_DishRow(d, inferred, <String>[
        d.name.toLowerCase(),
        for (final s in d.sections) s.toLowerCase(),
        if (inferred != null) inferred.toLowerCase(),
      ]));
    }
    return out;
  }

  static List<_FacilityRow> _indexFacilities(List<Facility> facilities) {
    return [
      for (final f in facilities) _FacilityRow(f, f.name.toLowerCase()),
    ];
  }

  static List<_MementoRow> _indexMementos(List<MementoEntry> mementos) {
    return [
      for (final m in mementos)
        _MementoRow(m, <String>[
          m.name.toLowerCase(),
          m.description.toLowerCase(),
          if (m.customerName != null) m.customerName!.toLowerCase(),
        ]),
    ];
  }

  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchHit>[];
    await preload();

    final hits = <SearchHit>[];

    // Customers
    for (final r in _customers ?? const <_CustomerRow>[]) {
      if (_anyContains(r.keys, q)) {
        hits.add(SearchHit(HitType.customer, r.customer.id, r.customer.name));
      }
    }

    // Letters
    for (final r in _letters ?? const <_LetterRow>[]) {
      if (_anyContains(r.keys, q)) {
        hits.add(SearchHit(HitType.letter, r.letter.id, r.letter.name,
            subtitle: r.letter.series));
      }
    }

    // Dishes (no d.category anymore -> inferred from sections at index time)
    for (final r in _dishes ?? const <_DishRow>[]) {
      if (_anyContains(r.keys, q)) {
        hits.add(SearchHit(HitType.dish, r.dish.id, r.dish.name,
            subtitle: r.inferred));
      }
    }

    // Facilities
    for (final r in _facilities ?? const <_FacilityRow>[]) {
      if (r.nameLower.contains(q)) {
        hits.add(
            SearchHit(HitType.facility, r.facility.id, r.facility.name));
      }
    }

    // Mementos
    for (final r in _mementos ?? const <_MementoRow>[]) {
      if (_anyContains(r.keys, q)) {
        hits.add(SearchHit(
          HitType.memento,
          r.memento.id,
          r.memento.name,
          subtitle: r.memento.customerName,
          key: r.memento.key,
        ));
      }
    }

    // Stable order by type then title
    hits.sort((a, b) {
      final t = a.type.index.compareTo(b.type.index);
      return t != 0 ? t : a.title.compareTo(b.title);
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
