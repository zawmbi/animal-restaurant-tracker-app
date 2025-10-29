// ignore_for_file: unused_import

import 'package:animal_restaurant_tracker/features/facilities/model/data/facilities_repository.dart';
import 'package:flutter/foundation.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/model/customer.dart';
import '../../letters/data/letters_repository.dart';
import '../../letters/model/letter.dart';
import '../../dishes/data/dishes_repository.dart';
import '../../dishes/model/dish.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';
import '../../mementos/data/mementos_index.dart';

enum HitType { customer, letter, dish, facility, memento }

class SearchHit {
  final HitType type;
  final String id;         // main id
  final String title;
  final String? subtitle;  // optional (e.g., customer name for a memento)
  final String? key;       // for mementos we store the composite key
  const SearchHit(this.type, this.id, this.title, {this.subtitle, this.key});
}

class SearchIndex {
  SearchIndex._();
  static final SearchIndex instance = SearchIndex._();

  List<Customer>? _customers;
  List<Letter>? _letters;
  List<Dish>? _dishes;
  List<Facility>? _facilities;

  Future<void> preload() async {
    _customers ??= await CustomersRepository.instance.all();
    _letters ??= await LettersRepository.instance.all();
    try { _dishes ??= await DishesRepository.instance.all(); } catch (_) {}
    try { _facilities ??= await FacilitiesRepository.instance.all(); } catch (_) {}
  }

  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchHit>[];
    await preload();

    final hits = <SearchHit>[];

    for (final c in _customers ?? const <Customer>[]) {
      if (c.name.toLowerCase().contains(q) || c.tags.any((t) => t.toLowerCase().contains(q))) {
        hits.add(SearchHit(HitType.customer, c.id, c.name));
      }
    }
    for (final l in _letters ?? const <Letter>[]) {
      if (l.name.toLowerCase().contains(q) || (l.series?.toLowerCase().contains(q) ?? false)) {
        hits.add(SearchHit(HitType.letter, l.id, l.name, subtitle: l.series));
      }
    }
    for (final d in _dishes ?? const <Dish>[]) {
      if (d.name.toLowerCase().contains(q) || (d.category?.toLowerCase().contains(q) ?? false)) {
        hits.add(SearchHit(HitType.dish, d.id, d.name, subtitle: d.category));
      }
    }
    for (final f in _facilities ?? const <Facility>[]) {
      if (f.name.toLowerCase().contains(q)) {
        hits.add(SearchHit(HitType.facility, f.id, f.name));
      }
    }

    // Mementos: use the index and search in name/description/customer
    try {
      final mementos = await MementosIndex.instance.all(search: q);
      for (final m in mementos) {
        hits.add(SearchHit(HitType.memento, m.id, m.name, subtitle: m.customerName, key: m.key));
      }
    } catch (_) {}

    // Optional: stable order by type then title
    hits.sort((a, b) {
      final t = a.type.index.compareTo(b.type.index);
      return t != 0 ? t : a.title.compareTo(b.title);
    });

    return hits;
  }
}