// Linked ids (a poster on the Posters page and the same poster on the
// Mementos page) and the global undo.
//
// Guest mode throughout, so no Firestore call is reached; see
// unlocked_store_test.dart for why that is safe.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/shared/data/progress_links.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = UnlockedStore.instance;
  const poster = 'poster';
  const memento = 'memento_collected';
  const pair = (poster, 'melt_your_heart', memento, 'm:cutie_hamster/melt_your_heart');

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.debugResetForTest();
    UnlockedStore.undoMergeWindow = Duration.zero;
    await store.init();
  });

  tearDown(() {
    store.debugResetForTest();
    UnlockedStore.undoMergeWindow = const Duration(milliseconds: 400);
  });

  group('linked ids', () {
    test('checking either side checks both, unchecking clears both', () async {
      await store.linkIds([pair]);

      await store.setUnlocked(poster, pair.$2, true);
      expect(store.isUnlocked(memento, pair.$4), isTrue);

      await store.setUnlocked(memento, pair.$4, false);
      expect(store.isUnlocked(poster, pair.$2), isFalse);
    });

    test('check all mirrors too', () async {
      await store.linkIds([pair]);
      await store.setManyUnlocked(memento, [pair.$4, 'x:other'], true);
      expect(store.isUnlocked(poster, pair.$2), isTrue);
    });

    test('progress saved before linking is merged, never removed', () async {
      await store.setUnlocked(memento, pair.$4, true);
      expect(store.isUnlocked(poster, pair.$2), isFalse);

      await store.linkIds([pair]);
      expect(store.isUnlocked(poster, pair.$2), isTrue);
      expect(store.isUnlocked(memento, pair.$4), isTrue);
    });

    test('the merge persists across a relaunch', () async {
      await store.setUnlocked(poster, pair.$2, true);
      await store.linkIds([pair]);

      store.debugResetForTest();
      await store.init();
      expect(store.isUnlocked(memento, pair.$4), isTrue);
    });

    test('real data links posters to their Poster-tab mementos', () async {
      final pairs = await posterMementoPairs();
      // 111 posters share an id with a memento tagged 'poster'.
      expect(pairs.length, greaterThanOrEqualTo(111));
      for (final (a, _, b, key) in pairs) {
        expect(a, poster);
        expect(b, memento);
        expect(key, anyOf(startsWith('m:'), startsWith('x:')));
      }
    });
  });

  group('undo', () {
    test('undoes only the most recent change', () async {
      await store.setUnlocked('dish', 'a', true);
      await store.setUnlocked('dish', 'b', true);

      expect(await store.undoLast(), isTrue);
      expect(store.isUnlocked('dish', 'a'), isTrue);
      expect(store.isUnlocked('dish', 'b'), isFalse);
    });

    test('undoing an uncheck puts it back', () async {
      await store.setUnlocked('dish', 'a', true);
      await store.setUnlocked('dish', 'a', false);
      await store.undoLast();
      expect(store.isUnlocked('dish', 'a'), isTrue);
    });

    test('undoing a check-all leaves what was already checked', () async {
      await store.setUnlocked('dish', 'a', true);
      await store.setManyUnlocked('dish', ['a', 'b', 'c'], true);
      await store.undoLast();
      expect(store.ids('dish'), {'a'});
    });

    test('undo reverts both sides of a link as one change', () async {
      await store.linkIds([pair]);
      await store.setUnlocked(poster, pair.$2, true);

      final entry = store.lastChange.value!;
      expect(entry.count, 1);
      expect(entry.wasCheck, isTrue);

      await store.undoLast();
      expect(store.isUnlocked(poster, pair.$2), isFalse);
      expect(store.isUnlocked(memento, pair.$4), isFalse);
    });

    test('writes inside the merge window are one undo', () async {
      UnlockedStore.undoMergeWindow = const Duration(seconds: 5);
      await store.setUnlocked('pet_mature', 'p', true);
      await store.setUnlocked('pet_owned', 'p', true);

      await store.undoLast();
      expect(store.isUnlocked('pet_mature', 'p'), isFalse);
      expect(store.isUnlocked('pet_owned', 'p'), isFalse);
      expect(store.canUndo, isFalse);
    });

    test('a no-op write records nothing', () async {
      await store.setUnlocked('dish', 'a', false);
      expect(store.canUndo, isFalse);
    });

    test('wiping all data clears the undo history', () async {
      await store.setUnlocked('dish', 'a', true);
      await store.clearAll();
      expect(store.canUndo, isFalse);
      expect(await store.undoLast(), isFalse);
    });
  });
}
