// Round-trip tests for the store that holds every piece of tracked progress.
//
// The bug these exist for: a bucket that is written but not loaded on the next
// launch reads back empty, and the first write after that overwrites the saved
// list. Nothing in the UI shows an error; the player just finds their progress
// gone. Five rounds of that have already shipped on this branch.
//
// Everything here runs in guest mode, so no Firestore call is ever reached
// (`UnlockedStore` guards all of them on `_user != null`, and `_user` stays
// null without `attachUser`). Firebase cannot initialise in a unit test and is
// not needed for any of this.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/completion/data/progress_types.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = UnlockedStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.debugResetForTest();
    await store.init();
  });

  tearDown(() {
    store.debugResetForTest();
  });

  /// Simulates a force-quit and relaunch: drop every scrap of in-memory state
  /// and let `init()` read SharedPreferences again, exactly as `main()` does.
  Future<void> relaunch() async {
    store.debugResetForTest();
    await store.init();
  }

  group('round trip across a relaunch', () {
    test('every startup bucket survives a relaunch', () async {
      for (final bucket in UnlockedStore.startupBuckets) {
        await store.setUnlocked(bucket, 'id_for_$bucket', true);
      }

      await relaunch();

      for (final bucket in UnlockedStore.startupBuckets) {
        expect(
          store.isUnlocked(bucket, 'id_for_$bucket'),
          isTrue,
          reason: 'bucket "$bucket" lost its ids across a relaunch. Either it '
              'is missing from UnlockedStore._defaultTypes, or its prefs key '
              'changed.',
        );
      }
    });

    test('every bucket the completion page counts survives a relaunch',
        () async {
      for (final bucket in ProgressTypes.registerOnStartup) {
        await store.setManyUnlocked(bucket, <String>['a', 'b', 'c'], true);
      }

      await relaunch();

      for (final bucket in ProgressTypes.registerOnStartup) {
        expect(store.ids(bucket), containsAll(<String>['a', 'b', 'c']),
            reason: 'bucket "$bucket" is counted by CompletionService but did '
                'not load on startup.');
      }
    });

    test('a bucket outside the startup list reads empty until registered',
        () async {
      // This is the failure mode, pinned so it cannot be mistaken for
      // acceptable behaviour. 'battle_pass' is written by
      // lib/home/ui/home_page.dart and is in no startup list.
      const stray = 'not_a_startup_bucket';
      await store.setUnlocked(stray, 'x', true);
      expect(store.isUnlocked(stray, 'x'), isTrue);

      await relaunch();

      expect(store.isUnlocked(stray, 'x'), isFalse,
          reason: 'an unregistered bucket is expected to read empty; if this '
              'ever passes, the startup loading rules changed');

      await store.registerType(stray);
      expect(store.isUnlocked(stray, 'x'), isTrue,
          reason: 'registerType must recover the ids that were saved anyway');
    });
  });

  group('writes', () {
    test('setUnlocked toggles one id and leaves the rest alone', () async {
      await store.setManyUnlocked('dish', <String>['a', 'b'], true);
      await store.setUnlocked('dish', 'a', false);

      expect(store.isUnlocked('dish', 'a'), isFalse);
      expect(store.isUnlocked('dish', 'b'), isTrue);
      expect(store.count('dish'), 1);
    });

    test('setManyUnlocked writes the whole batch and is idempotent', () async {
      final ids = List<String>.generate(500, (i) => 'dish_$i');

      await store.setManyUnlocked('dish', ids, true);
      expect(store.count('dish'), 500);

      await store.setManyUnlocked('dish', ids, true);
      expect(store.count('dish'), 500);

      await store.setManyUnlocked('dish', ids, false);
      expect(store.count('dish'), 0);
    });

    test('a large batch survives a relaunch intact', () async {
      final ids = List<String>.generate(1184, (i) => 'm:c$i/memento_$i');
      await store.setManyUnlocked('memento_collected', ids, true);

      await relaunch();

      expect(store.count('memento_collected'), 1184);
      expect(store.isUnlocked('memento_collected', 'm:c0/memento_0'), isTrue);
      expect(store.isUnlocked('memento_collected', 'm:c1183/memento_1183'),
          isTrue);
    });

    test('ids() hands back an unmodifiable view', () async {
      await store.setUnlocked('dish', 'a', true);
      expect(() => store.ids('dish').add('b'), throwsUnsupportedError);
    });

    test('toggle flips and flips back', () async {
      await store.toggle('letter', 'l1');
      expect(store.isUnlocked('letter', 'l1'), isTrue);
      await store.toggle('letter', 'l1');
      expect(store.isUnlocked('letter', 'l1'), isFalse);
    });
  });

  group('clearing', () {
    test('clearType empties one bucket and only that bucket', () async {
      await store.setUnlocked('dish', 'a', true);
      await store.setUnlocked('letter', 'b', true);

      await store.clearType('dish');

      expect(store.count('dish'), 0);
      expect(store.isUnlocked('letter', 'b'), isTrue);
    });

    test('clearAll empties everything, and it stays empty after a relaunch',
        () async {
      await store.setUnlocked('dish', 'a', true);
      await store.setUnlocked('customers', 'white_bunny', true);

      await store.clearAll();
      await relaunch();

      expect(store.count('dish'), 0);
      expect(store.count('customers'), 0);
    });
  });

  group('notifications', () {
    test('one setManyUnlocked notifies once, not once per id', () async {
      var notifications = 0;
      void listener() => notifications++;
      store.addListener(listener);
      addTearDown(() => store.removeListener(listener));

      await store.setManyUnlocked(
        'dish',
        List<String>.generate(200, (i) => 'd$i'),
        true,
      );

      expect(notifications, 1,
          reason: 'a bulk write that notifies per id makes "Check all" on a '
              'large group rebuild the list hundreds of times');
    });

    test('a write that changes nothing does not notify', () async {
      await store.setUnlocked('dish', 'a', true);

      var notifications = 0;
      void listener() => notifications++;
      store.addListener(listener);
      addTearDown(() => store.removeListener(listener));

      await store.setUnlocked('dish', 'a', true);
      await store.setManyUnlocked('dish', <String>['a'], true);

      expect(notifications, 0);
    });
  });

  group('namespaces', () {
    test('guest is the namespace before any sign-in', () {
      expect(store.activeNamespace, 'guest');
    });

    test('progress saved as a guest is still there after a relaunch', () async {
      await store.setUnlocked('customers', 'white_bunny', true);
      await relaunch();
      expect(store.activeNamespace, 'guest');
      expect(store.isUnlocked('customers', 'white_bunny'), isTrue);
    });

    // Guest <-> uid switching needs a real firebase_auth `User`, which cannot
    // be constructed in a unit test. It is covered manually in
    // docs/qa-report.md's scenario matrix instead of being faked here.
  });

  group('export', () {
    test('exportSnapshot is what would be uploaded, and matches memory',
        () async {
      await store.setManyUnlocked('dish', <String>['a', 'b'], true);
      await store.setUnlocked('customers', 'white_bunny', true);

      final snapshot = store.exportSnapshot();

      expect(snapshot['dish'], containsAll(<String>['a', 'b']));
      expect(snapshot['customers'], contains('white_bunny'));
      for (final bucket in UnlockedStore.startupBuckets) {
        expect(snapshot.containsKey(bucket), isTrue,
            reason: 'a bucket missing from the upload is a bucket the cloud '
                'copy silently drops');
      }
    });
  });
}
