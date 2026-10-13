// The terrace "Customers pay" card on FacilityDetailPage actually renders.
//
// terrace_pay_projection_test.dart covers the arithmetic; this covers the part
// the player complained about — that a table's effect on their takings was
// computed nowhere and shown nowhere on its own page.
//
// Guest mode throughout, so no Firestore call is reachable (UnlockedStore
// guards those on a non-null user, and attachUser is never called here).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/completion/data/progress_types.dart';
import 'package:animal_restaurant_tracker/features/economy/data/income_repository.dart';
import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart';
import 'package:animal_restaurant_tracker/features/economy/data/terrace_observation_store.dart';
import 'package:animal_restaurant_tracker/features/facilities/ui/facility_detail_page.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = UnlockedStore.instance;
  final observations = TerraceObservationStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.debugResetForTest();
    observations.debugResetForTest();
    await store.init();
  });

  tearDown(() {
    store.debugResetForTest();
    observations.debugResetForTest();
  });

  Future<void> pumpDetail(WidgetTester tester, String facilityId) async {
    // Warm every source the page awaits, on the real event loop. The page
    // starts its load in initState, and `tester.pump` does not flush the
    // platform-channel reply that SharedPreferences waits on — so without this
    // the page sits on its spinner forever. Once these are cached, the page's
    // own awaits resolve in microtasks and a plain pump is enough.
    await tester.runAsync(() async {
      await IncomeRepository.instance.ensureLoaded();
      await FacilitiesRepository.instance.all();
      await observations.ensureLoaded();
    });

    await tester.pumpWidget(
      MaterialApp(home: FacilityDetailPage(facilityId: facilityId)),
    );

    // The page kicks off its own load in initState, and those continuations
    // run on the real event loop, which `pump` does not drive. Give them a
    // moment, then pump to pick up the resolved FutureBuilder.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));

    // Not pumpAndSettle: the loading state is a CircularProgressIndicator,
    // which schedules frames forever, so settling never happens while it is on
    // screen. Pump a couple of explicit frames instead.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a percentage table shows the raise it is actually worth',
      (tester) async {
    // Natural Scenery is +5% and the terrace is empty, so the raise is 5%.
    await pumpDetail(tester, 'natural_scenery');

    expect(find.text('Customers pay'), findsOneWidget);
    expect(
      find.textContaining('raises your terrace takings by 5%'),
      findsOneWidget,
    );
  });

  testWidgets('the raise shrinks as the terrace fills up', (tester) async {
    // Own Family Table (+8%) and Academy Meeting (+10%), so 18% is already
    // banked. Adding Natural Scenery's 5 points lifts a 118% payment to 123%,
    // which is a 4.2% raise on current takings rather than the 5% on the label.
    await store.setUnlocked(ProgressTypes.facility, 'family_table', true);
    await store.setUnlocked(ProgressTypes.facility, 'academy_meeting', true);

    await pumpDetail(tester, 'natural_scenery');

    expect(find.textContaining('2 of 89 pay tables'), findsOneWidget);
    expect(
      find.textContaining('raises your terrace takings by 4.2%'),
      findsOneWidget,
    );
  });

  testWidgets('a flat table refuses to invent a per-gather figure',
      (tester) async {
    await pumpDetail(tester, 'candy_feast');

    expect(
      find.textContaining('adds +200,000 cod to what each terrace customer'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not publish how many customers'),
      findsOneWidget,
    );
  });

  testWidgets('an observed gather turns the raise into cod', (tester) async {
    await observations.setCodPerGather(1000000);

    await pumpDetail(tester, 'natural_scenery');

    // 5% of a 1,000,000 cod gather.
    expect(find.textContaining('+50,000 cod'), findsOneWidget);
  });

  testWidgets('an already-unlocked table adds nothing', (tester) async {
    await store.setUnlocked(ProgressTypes.facility, 'natural_scenery', true);

    await pumpDetail(tester, 'natural_scenery');

    expect(find.textContaining('Already ticked off'), findsOneWidget);
    expect(find.textContaining('raises your terrace takings'), findsNothing);
  });

  testWidgets('a non-terrace facility gets no pay card', (tester) async {
    await pumpDetail(tester, 'old_telescope');

    expect(find.text('Customers pay'), findsNothing);
    // It still shows its own income channel, which was invisible before.
    expect(find.textContaining('views a flower'), findsOneWidget);
  });
}
