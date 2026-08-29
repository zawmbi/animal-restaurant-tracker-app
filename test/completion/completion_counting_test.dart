// Completion counting: the number on the front of the app.
//
// Two things have to hold and neither is obvious from reading the code:
//
//  * 0% at zero progress and exactly 100% when every id is checked. Anything
//    else means a category is counting ids no screen can reach, or counting
//    the same collectible twice.
//  * Mementos are counted once. 123 of the 1,184 mementos are also embedded
//    inside customers.json; summing both sets inflates the denominator
//    permanently.
//
// The arithmetic here runs against CompletionCategory / CompletionData with
// hand-built parts, so it needs no asset bundle. The dataset invariants read
// the shipped JSON straight off disk.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/completion/data/completion_service.dart';
import 'package:animal_restaurant_tracker/features/completion/data/progress_types.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

import '../support/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = UnlockedStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store.debugResetForTest();
    await store.init();
  });

  tearDown(() => store.debugResetForTest());

  CompletionCategory categoryOf(String bucket, List<String> ids,
          {bool counts = true}) =>
      CompletionCategory(
        key: bucket,
        label: bucket,
        parts: <CompletionPart>[CompletionPart(bucket, ids)],
        countsTowardTotal: counts,
      );

  group('a single category', () {
    test('reads 0 with nothing checked and 1.0 with everything checked',
        () async {
      final category = categoryOf('dish', <String>['a', 'b', 'c', 'd']);

      expect(category.collected(store), 0);
      expect(category.fraction(store), 0.0);

      await store.setManyUnlocked('dish', <String>['a', 'b', 'c', 'd'], true);

      expect(category.collected(store), 4);
      expect(category.fraction(store), 1.0);
    });

    test('an empty category reads 0, not NaN', () {
      final category = categoryOf('dish', const <String>[]);
      expect(category.total(store), 0);
      expect(category.fraction(store), 0.0);
      expect(category.fraction(store).isNaN, isFalse);
    });

    test('checking an id in a different bucket does not move it', () async {
      final category = categoryOf('dish', <String>['a']);
      await store.setUnlocked('letter', 'a', true);
      expect(category.collected(store), 0,
          reason: 'ids are only meaningful inside their own bucket');
    });

    test('checking an id the category does not list does not move it',
        () async {
      final category = categoryOf('dish', <String>['a']);
      await store.setUnlocked('dish', 'not_listed', true);
      expect(category.collected(store), 0);
      expect(category.total(store), 1);
    });
  });

  group('the overall percentage', () {
    test('is exactly 0 at zero progress and exactly 1.0 when all is checked',
        () async {
      final data = CompletionData(<CompletionCategory>[
        categoryOf('dish', <String>['d1', 'd2']),
        categoryOf('letter', <String>['l1', 'l2', 'l3']),
        categoryOf('customers', <String>['c1']),
      ]);

      expect(data.overallTotal(store), 6);
      expect(data.overallCollected(store), 0);
      expect(data.overallFraction(store), 0.0);

      await store.setManyUnlocked('dish', <String>['d1', 'd2'], true);
      await store.setManyUnlocked('letter', <String>['l1', 'l2', 'l3'], true);
      await store.setUnlocked('customers', 'c1', true);

      expect(data.overallCollected(store), 6);
      expect(data.overallFraction(store), 1.0,
          reason: '100% must be exactly reachable, not 99.9%');
    });

    test('a subset category is excluded from the total, not double counted',
        () async {
      // Booth owners are customers. Counting the row twice would make a booth
      // owner worth two collectibles.
      final data = CompletionData(<CompletionCategory>[
        categoryOf('customers', <String>['c1', 'c2', 'c3']),
        categoryOf('customers', <String>['c1'], counts: false),
      ]);

      expect(data.overallTotal(store), 3);

      await store.setUnlocked('customers', 'c1', true);
      expect(data.overallCollected(store), 1);
    });

    test('an unavailable category is left out of the total entirely', () {
      final data = CompletionData(<CompletionCategory>[
        categoryOf('dish', <String>['d1', 'd2']),
        const CompletionCategory(
          key: 'broken',
          label: 'broken',
          parts: <CompletionPart>[CompletionPart('letter', <String>['l1'])],
          error: 'asset missing',
        ),
      ]);

      expect(data.overallTotal(store), 2,
          reason: 'a category that failed to load must not silently shrink '
              'the percentage by sitting in the denominator with 0 collected');
    });

    test('a gated part joins both numerator and denominator together',
        () async {
      // The battle pass Super track only exists once premium is owned.
      final category = CompletionCategory(
        key: 'bp',
        label: 'Battle Pass',
        parts: <CompletionPart>[
          const CompletionPart(ProgressTypes.battlePassClaimed, <String>['n1']),
          CompletionPart(
            ProgressTypes.battlePassClaimed,
            const <String>['s1'],
            enabled: (s) =>
                s.isUnlocked(ProgressTypes.battlePassPremium, 'pass'),
          ),
        ],
      );

      expect(category.total(store), 1,
          reason: 'without premium the Super track is not a collectible');

      await store.setUnlocked(ProgressTypes.battlePassPremium, 'pass', true);
      expect(category.total(store), 2);

      await store.setManyUnlocked(
          ProgressTypes.battlePassClaimed, <String>['n1', 's1'], true);
      expect(category.fraction(store), 1.0);
    });

    test('buying premium after claiming the normal track cannot exceed 100%',
        () async {
      final category = CompletionCategory(
        key: 'bp',
        label: 'Battle Pass',
        parts: <CompletionPart>[
          const CompletionPart(ProgressTypes.battlePassClaimed, <String>['n1']),
          CompletionPart(
            ProgressTypes.battlePassClaimed,
            const <String>['s1'],
            enabled: (s) =>
                s.isUnlocked(ProgressTypes.battlePassPremium, 'pass'),
          ),
        ],
      );

      // BattlePassDetailPage._setTierClaimedForPhase writes BOTH the normal and
      // the super key even for a player with no premium, so this is the real
      // stored state after a free player ticks a tier.
      await store.setManyUnlocked(
          ProgressTypes.battlePassClaimed, <String>['n1', 's1'], true);
      expect(category.fraction(store), 1.0);

      await store.setUnlocked(ProgressTypes.battlePassPremium, 'pass', true);
      expect(category.fraction(store), lessThanOrEqualTo(1.0));
      expect(category.fraction(store), 1.0,
          reason: 'the Super track reads as already claimed the moment premium '
              'is switched on, because the free-player tick wrote its key too. '
              'That is a real defect, pinned here so a fix has a test.');
    });
  });

  group('mementos are counted once', () {
    final registry = readJsonList('assets/data/mementos.json');
    final customers = readJsonList('assets/data/customers.json');

    test('mementos.json has no duplicate ids', () {
      final ids = registry.map((m) => m['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every memento embedded in a customer is the same collectible as the '
        'one in mementos.json', () {
      final byId = <String, Map<String, dynamic>>{
        for (final m in registry) m['id'] as String: m,
      };

      var embedded = 0;
      for (final customer in customers) {
        for (final raw in (customer['mementos'] as List? ?? const <dynamic>[])) {
          embedded++;
          final id = (raw as Map)['id'] as String;
          expect(byId.containsKey(id), isTrue,
              reason: 'customer ${customer['id']} embeds memento "$id", which '
                  'is not in mementos.json — it would be an extra collectible '
                  'nothing counts');
          expect(byId[id]!['customerId'], customer['id'],
              reason: 'memento "$id" is embedded under ${customer['id']} but '
                  'mementos.json says it belongs to '
                  '${byId[id]!['customerId']}');
        }
      }
      expect(embedded, 123,
          reason: 'the number of customer-linked mementos changed; check the '
              'denominator still adds up');
    });

    test('the key scheme gives every memento exactly one key', () {
      // MementosIndex builds 'm:<customerId>/<id>' when the memento belongs to
      // a customer and 'x:<id>' when it does not.
      final keys = <String>{};
      for (final m in registry) {
        final id = m['id'] as String;
        final customerId = m['customerId'] as String?;
        final key = customerId != null ? 'm:$customerId/$id' : 'x:$id';
        expect(keys.add(key), isTrue,
            reason: 'two mementos would share the storage key "$key"');
      }
      expect(keys.length, registry.length);
      expect(keys.length, 1184);
    });
  });

  group('facility ids are unique inside their bucket', () {
    test("no id appears twice among the areas the 'facility' bucket covers",
        () {
      final seen = <String, String>{};
      final collisions = <String>[];
      for (final area in facilitySceneAreas) {
        for (final row in facilityRowsForArea(area)) {
          final id = row['id'] as String;
          if (seen.containsKey(id)) {
            collisions.add('$id (${seen[id]} + $area)');
          } else {
            seen[id] = area;
          }
        }
      }
      expect(collisions, isEmpty,
          reason: 'these ids share the one "facility" bucket, so checking one '
              'silently checks the other and the denominator is short: '
              '$collisions');
    });

    test("no id is in both the 'facility' and the courtyard bucket", () {
      final sceneIds = <String>{
        for (final area in facilitySceneAreas)
          for (final row in facilityRowsForArea(area)) row['id'] as String,
      };
      final courtyardIds = <String>{
        for (final row in facilityRowsForArea('courtyard'))
          row['id'] as String,
      };
      final both = sceneIds.intersection(courtyardIds).toList()..sort();
      expect(both, isEmpty,
          reason: 'each of these counts twice toward 100% and has to be '
              'checked off on two different screens: $both');
    });
  });

  group('every counted collectible is reachable from some screen', () {
    test('every courtyard group has a tab on the Courtyard page', () {
      // CourtyardRepository.orderedGroups is the tab list; a group missing
      // from it has no checkbox anywhere, yet all 1,336 courtyard facilities
      // are in the completion denominator.
      const orderedGroups = <String>[
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

      final unreachable = <String, int>{};
      for (final row in facilityRowsForArea('courtyard')) {
        final group = row['group'] as String;
        if (!orderedGroups.contains(group)) {
          unreachable[group] = (unreachable[group] ?? 0) + 1;
        }
      }

      expect(unreachable, isEmpty,
          reason: 'these courtyard groups are counted toward 100% but have no '
              'tab, so they can never be checked off: $unreachable');
    });

    test('no facility shard is loaded but shown nowhere', () {
      // FacilitiesRepository loads the concert and pet-yard shards (global
      // search finds them), but FacilitiesPage excludes those areas and
      // CourtyardRepository only reads courtyard_facilities.json.
      final orphaned = <String, int>{
        for (final area in <String>['courtyard_concert', 'courtyard_pets'])
          area: facilityRowsForArea(area).length,
      };
      final total = orphaned.values.fold<int>(0, (a, b) => a + b);
      expect(total, 0,
          reason: 'facilities in areas no page renders and no category '
              'counts: $orphaned');
    });
  });
}
