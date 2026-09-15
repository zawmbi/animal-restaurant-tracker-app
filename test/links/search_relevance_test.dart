// Global search has to put what you typed at the top, and a tap on a result
// has to open that one thing.
//
// Both were broken in the shipped build: matching was a plain `contains` with
// results ordered by type and then alphabetically, so an exact name could sit
// below anything that merely mentioned it, and a two-word query only matched a
// literal substring. These use the real repositories and the real data.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/search/data/search_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('search relevance', () {
    test('typing a name in full puts that entity first', () async {
      final hits = await SearchIndex.instance.search('brown bunny');
      expect(hits, isNotEmpty);
      expect(hits.first.type, HitType.customer);
      expect(hits.first.title, 'Brown Bunny');
    });

    test('word order does not matter', () async {
      // 'contains' could never do this: the literal string "bunny brown"
      // appears in no name in the game.
      final hits = await SearchIndex.instance.search('bunny brown');
      expect(hits, isNotEmpty);
      expect(hits.first.title, 'Brown Bunny');
    });

    test('a partial last word still matches', () async {
      // What a user has typed by the time they are halfway through.
      final hits = await SearchIndex.instance.search('white bun');
      expect(
        hits.any((h) => h.type == HitType.customer && h.title == 'White Bunny'),
        isTrue,
        reason: 'a prefix of the final word should still find the customer',
      );
    });

    test('every word has to match something, so unrelated pairs find nothing',
        () async {
      final hits = await SearchIndex.instance.search('white truck');
      expect(
        hits.any((h) => h.title == 'White Bunny'),
        isFalse,
        reason: 'matching any one word would drag in half the game',
      );
    });

    test('a name match outranks a match buried in flavour text', () async {
      // 'Christmas Sleigh' says "deer" only in its description; nine mementos
      // carry it in the name. The description is the largest and least
      // specific surface in the app — 1,182 mementos have one — so it must
      // never outrank a name.
      final hits = await SearchIndex.instance.search('deer');
      final mementos = hits.where((h) => h.type == HitType.memento).toList();
      expect(mementos, isNotEmpty);

      final sleigh = mementos.indexWhere((h) => h.title == 'Christmas Sleigh');
      expect(sleigh, greaterThan(-1), reason: 'description matches still count');

      final named = mementos
          .where((h) => h.title.toLowerCase().contains('deer'))
          .toList();
      expect(named, isNotEmpty);
      for (final h in named) {
        expect(
          mementos.indexOf(h),
          lessThan(sleigh),
          reason: '${h.title} names the query and should rank above a '
              'memento that only mentions it',
        );
      }
    });

    test('the customer Deer beats every memento that mentions deer', () async {
      final hits = await SearchIndex.instance.search('deer');
      expect(hits.first.type, HitType.customer);
      expect(hits.first.title, 'Deer');
    });

    test('results come back sorted by score, and every hit scored', () async {
      final hits = await SearchIndex.instance.search('bunny');
      expect(hits, isNotEmpty);
      for (final h in hits) {
        expect(h.score, greaterThan(0));
      }
      for (var i = 1; i < hits.length; i++) {
        expect(
          hits[i - 1].score,
          greaterThanOrEqualTo(hits[i].score),
          reason: 'hit $i broke the ordering',
        );
      }
    });

    test('an empty or whitespace query returns nothing', () async {
      expect(await SearchIndex.instance.search(''), isEmpty);
      expect(await SearchIndex.instance.search('   '), isEmpty);
    });
  });
}
