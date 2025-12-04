import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'courtyard_facilities.dart';

class CourtyardRepository {
  CourtyardRepository._();

  static final CourtyardRepository instance = CourtyardRepository._();

  bool _loaded = false;
  List<CourtyardFacility> _facilities = [];

  /// Call this once (the page will use a FutureBuilder) to make sure
  /// the JSON is loaded.
  Future<void> ensureLoaded() async {
    if (_loaded) return;

    // Adjust the path if your assets are under a different folder.
    final raw =
        await rootBundle.loadString('assets/data/facilities_jsons/courtyard_facilities.json');

    final List<dynamic> data = json.decode(raw) as List<dynamic>;

    _facilities = data
        .map((e) => CourtyardFacility.fromJson(e as Map<String, dynamic>))
        .toList();

    _loaded = true;
  }

  bool get isLoaded => _loaded;

  List<CourtyardFacility> get allFacilities => List.unmodifiable(_facilities);

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
    final existing = {
      for (final f in _facilities) f.group,
    };
    return orderedGroups.where(existing.contains).toList();
  }

  /// Unique list of series (themes) sorted alphabetically.
  List<String> allSeriesSorted() {
    final set = <String>{};

    for (final f in _facilities) {
      final s = f.series;
      if (s != null && s.isNotEmpty) {
        set.add(s);
      }
    }

    final list = set.toList()..sort();
    return list;
  }

  /// Facilities filtered by group and optional series.
  List<CourtyardFacility> byGroupAndSeries(
    String group, {
    String? series,
  }) {
    return _facilities.where((f) {
      if (f.group != group) return false;
      if (series != null && series.isNotEmpty && series != 'All') {
        return f.series == series;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
