// "What am I still missing?" is the collector's whole question, and no list in
// the app could answer it. This holds the filter's semantics, which are easy
// to get backwards.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/shared/widgets/owned_filter.dart';

void main() {
  test('All shows everything', () {
    expect(OwnedFilter.all.allows(true), isTrue);
    expect(OwnedFilter.all.allows(false), isTrue);
  });

  test('Missing shows only what is not owned', () {
    expect(OwnedFilter.missing.allows(false), isTrue);
    expect(OwnedFilter.missing.allows(true), isFalse);
  });

  test('Owned shows only what is owned', () {
    expect(OwnedFilter.owned.allows(true), isTrue);
    expect(OwnedFilter.owned.allows(false), isFalse);
  });

  test('every option has a label and they are distinct', () {
    final labels = OwnedFilter.values.map((f) => f.label).toList();
    expect(labels, hasLength(3));
    expect(labels.toSet(), hasLength(3));
    for (final l in labels) {
      expect(l, isNotEmpty);
    }
  });
}
