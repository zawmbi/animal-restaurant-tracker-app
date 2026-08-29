// "Check all" is the fastest way for a player to destroy real progress, so
// the confirmation, the label and the single-write behaviour all matter.
//
// Widget tests only: no Firebase, no assets. The store is driven through the
// SharedPreferences mock, exactly as in test/progress/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';
import 'package:animal_restaurant_tracker/features/shared/widgets/check_all_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = UnlockedStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.debugResetForTest();
    await store.init();
  });

  tearDown(() => store.debugResetForTest());

  Future<void> pumpButton(WidgetTester tester, Widget button) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: button))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reads "Check all" when nothing is checked', (tester) async {
    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: const <String>['a', 'b', 'c']),
    );
    expect(find.text('Check all'), findsOneWidget);
    expect(find.text('Uncheck all'), findsNothing);
  });

  testWidgets('checks the whole group in one tap', (tester) async {
    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: const <String>['a', 'b', 'c']),
    );

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(store.isUnlocked('dish', 'a'), isTrue);
    expect(store.isUnlocked('dish', 'b'), isTrue);
    expect(store.isUnlocked('dish', 'c'), isTrue);
  });

  testWidgets('flips its own label without the page rebuilding it',
      (tester) async {
    // The button listens to the store itself, so it stays correct on pages
    // that do not wrap their body in an AnimatedBuilder.
    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: const <String>['a', 'b']),
    );

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(find.text('Uncheck all'), findsOneWidget);
  });

  testWidgets('unchecking a small group needs no confirmation', (tester) async {
    await store.setManyUnlocked('dish', const <String>['a', 'b'], true);

    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: const <String>['a', 'b']),
    );

    await tester.tap(find.text('Uncheck all'));
    await tester.pumpAndSettle();

    expect(find.text('Uncheck all?'), findsNothing);
    expect(store.count('dish'), 0);
  });

  testWidgets('unchecking a large group asks first, and Cancel keeps progress',
      (tester) async {
    final ids = List<String>.generate(50, (i) => 'd$i');
    await store.setManyUnlocked('dish', ids, true);

    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: ids, groupLabel: 'Recipes'),
    );

    await tester.tap(find.text('Uncheck all'));
    await tester.pumpAndSettle();

    expect(find.text('Uncheck all?'), findsOneWidget);
    expect(find.textContaining('50 checked items'), findsOneWidget);
    expect(find.textContaining('in Recipes'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.count('dish'), 50,
        reason: 'cancelling must not clear anything');
  });

  testWidgets('confirming the dialog clears the group', (tester) async {
    final ids = List<String>.generate(50, (i) => 'd$i');
    await store.setManyUnlocked('dish', ids, true);

    await pumpButton(tester, CheckAllButton(bucket: 'dish', ids: ids));

    await tester.tap(find.text('Uncheck all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, uncheck all'));
    await tester.pumpAndSettle();

    expect(store.count('dish'), 0);
  });

  testWidgets('the dialog uses the singular for one item', (tester) async {
    await store.setUnlocked('dish', 'only', true);

    await pumpButton(
      tester,
      CheckAllButton(
        bucket: 'dish',
        ids: const <String>['only'],
        confirmThreshold: 0,
      ),
    );

    await tester.tap(find.text('Uncheck all'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 checked item.'), findsOneWidget);
    expect(find.textContaining('checked items'), findsNothing);
  });

  testWidgets('checking never asks for confirmation', (tester) async {
    final ids = List<String>.generate(500, (i) => 'd$i');

    await pumpButton(tester, CheckAllButton(bucket: 'dish', ids: ids));

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(find.text('Uncheck all?'), findsNothing);
    expect(store.count('dish'), 500);
  });

  testWidgets('an empty group renders nothing at all', (tester) async {
    await pumpButton(
      tester,
      CheckAllButton(bucket: 'dish', ids: const <String>[]),
    );
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('a multi-bucket group is all-or-nothing across both buckets',
      (tester) async {
    // Pets: rooms and photo tasks live in different buckets but are one group
    // on the page.
    await pumpButton(
      tester,
      const CheckAllButton.multi(
        targets: <CheckAllTarget>[
          CheckAllTarget('pet_room_unlocked', <String>['room_1', 'room_2']),
          CheckAllTarget('pet_photo_task_done', <String>['task_1']),
        ],
      ),
    );

    // One bucket already full must not make the label read "Uncheck all".
    await store.setManyUnlocked(
        'pet_room_unlocked', const <String>['room_1', 'room_2'], true);
    await tester.pumpAndSettle();
    expect(find.text('Check all'), findsOneWidget);

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(store.isUnlocked('pet_photo_task_done', 'task_1'), isTrue);
    expect(find.text('Uncheck all'), findsOneWidget);
  });

  testWidgets('onApplied is told which way the group was flipped',
      (tester) async {
    final applied = <bool>[];

    await pumpButton(
      tester,
      CheckAllButton(
        bucket: 'dish',
        ids: const <String>['a', 'b'],
        onApplied: applied.add,
      ),
    );

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uncheck all'));
    await tester.pumpAndSettle();

    expect(applied, <bool>[true, false]);
  });

  testWidgets('a 1,184-id group is one persist, not 1,184', (tester) async {
    var notifications = 0;
    void listener() => notifications++;
    store.addListener(listener);
    addTearDown(() => store.removeListener(listener));

    final ids = List<String>.generate(1184, (i) => 'm$i');
    await pumpButton(
      tester,
      CheckAllButton(bucket: 'memento_collected', ids: ids),
    );

    await tester.tap(find.text('Check all'));
    await tester.pumpAndSettle();

    expect(store.count('memento_collected'), 1184);
    expect(notifications, 1,
        reason: 'one notification for the batch; a per-id loop here rebuilt '
            'the mementos list 1,184 times');
  });
}
