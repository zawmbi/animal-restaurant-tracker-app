// "Information being related and linked together": every id a detail page
// renders as a tappable chip has to resolve to the entity of the right KIND,
// and the checkbox next to it has to read the same bucket the owning page
// writes.
//
// These use the real repositories, so they need `flutter test` and its asset
// bundle. Firebase is never touched.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/completion/data/progress_types.dart';
import 'package:animal_restaurant_tracker/features/customers/data/customers_repository.dart';
import 'package:animal_restaurant_tracker/features/dishes/data/dishes_repository.dart';
import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart';
import 'package:animal_restaurant_tracker/features/facilities/model/facility.dart';
import 'package:animal_restaurant_tracker/features/letters/data/letters_repository.dart';
import 'package:animal_restaurant_tracker/features/search/data/search_index.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

import '../support/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Customer detail -> Required Recipes', () {
    test('every recipe chip opens a recipe instead of "Recipe not found"',
        () async {
      // CustomerDetailPage pushes DishDetailPage(dishId: id) with the value
      // straight out of requirements.recipes, and DishDetailPage resolves it
      // with DishesRepository.byId.
      final customers = await CustomersRepository.instance.all();
      final repo = DishesRepository.instance;

      final dead = <String>{};
      for (final customer in customers) {
        for (final recipe in customer.requirements?.recipes ?? const <String>[]) {
          if (await repo.byId(recipe) == null) dead.add(recipe);
        }
      }

      expect(dead, isEmpty,
          reason: '${dead.length} distinct recipe chips dead-end. '
              'requirements.recipes holds display NAMES ("Adzuki Bean '
              'Dumpling") and byId lowercases without slugifying, so only '
              'single-word recipes resolve.');
    });

    test('the "owned" fill on a recipe chip can actually light up', () async {
      // requirements.recipes holds display names and the dish bucket holds
      // dish ids, so the chip used to compare a name against a bucket of ids
      // and could never fill. CustomerDetailPage now resolves the name to its
      // Dish first and checks `dish.id`; this pins that every requirement
      // still resolves, because one that does not goes back to never filling.
      final customers = await CustomersRepository.instance.all();
      final repo = DishesRepository.instance;

      final unresolvable = <String>{};
      for (final customer in customers) {
        for (final recipe
            in customer.requirements?.recipes ?? const <String>[]) {
          if (await repo.resolve(recipe) == null) unresolvable.add(recipe);
        }
      }

      expect(unresolvable, isEmpty,
          reason: '${unresolvable.length} recipe chips can never show as '
              'owned: nothing resolves them to a dish id');
    });

    test('resolve() accepts a name, which is what these call sites need',
        () async {
      final repo = DishesRepository.instance;
      expect(await repo.resolve('Adzuki Bean Dumpling'), isNotNull);
      expect(await repo.resolve('adzuki_bean_dumpling'), isNotNull);
      expect((await repo.resolve('Taiyaki'))!.id, 'taiyaki');
    });
  });

  group('Customer detail -> Required Facilities and Letters', () {
    // Requirements that name something no registry has. The wiki writes these
    // as prose on the customer page and there is no entity behind them, so
    // CustomerDetailPage renders them as plain untappable chips rather than
    // inventing a facility or a letter. Anything NOT on these lists has to
    // resolve, because it will be rendered as a live link.
    const unlinkedFacilities = <String>{'halloween_decorations'};
    const unlinkedLetters = <String>{
      'halloween_invitation',
      'white_shiba_intro_letter',
    };

    test('every facility chip resolves to a facility', () async {
      final customers = await CustomersRepository.instance.all();
      final repo = FacilitiesRepository.instance;

      final dead = <String>{};
      for (final customer in customers) {
        for (final id in customer.requirements?.facilities ?? const <String>[]) {
          if (unlinkedFacilities.contains(id)) continue;
          if (await repo.byId(id) == null) dead.add(id);
        }
      }
      expect(dead, isEmpty,
          reason: 'these chips open a FacilityDetailPage that says '
              '"Facility not found": $dead');
    });

    test('every letter chip resolves to a letter', () async {
      final customers = await CustomersRepository.instance.all();
      final repo = LettersRepository.instance;

      final dead = <String>{};
      for (final customer in customers) {
        for (final id in customer.requirements?.letters ?? const <String>[]) {
          if (unlinkedLetters.contains(id)) continue;
          if (await repo.byId(id) == null) dead.add(id);
        }
      }
      expect(dead, isEmpty,
          reason: 'these chips silently do nothing when tapped: $dead');
    });

    test('every prerequisite-customer chip resolves to a customer', () async {
      final repo = CustomersRepository.instance;
      final customers = await repo.all();

      final dead = <String>{};
      for (final customer in customers) {
        for (final id in customer.requirements?.customers ?? const <String>[]) {
          if (await repo.byId(id) == null) dead.add(id);
        }
      }
      expect(dead, isEmpty);
    });
  });

  group('Redemption codes -> gift', () {
    test('every code with a gift can be linked and checked off', () async {
      // A gift is a memento or a facility, and giftKind says which. The page
      // used to look every gift up in the memento index only, so the 38
      // facility gifts rendered as plain text with a dead checkbox — 40 of
      // the 91 codes could not be ticked off at all.
      //
      // Two codes are marked 'unresolved' in the data itself: their gift is
      // not in either registry ('osmanthus_hanging_ornament') or its name is
      // ambiguous between two different facilities that share a slug
      // ('gift_teddy_bear_2', which is both a free courtyard item and a 9.5M
      // terrace one). Those two stay untappable rather than guessing.
      final codes = readJsonList('assets/data/redemption_codes.json');
      final mementoIds = <String>{
        for (final m in readJsonList('assets/data/mementos.json'))
          m['id'] as String,
      };
      final facilityIds = <String>{
        for (final f in await FacilitiesRepository.instance.all()) f.id,
      };

      final unlinkable = <String>[];
      for (final code in codes) {
        final kind = code['giftKind'] as String?;
        if (kind == null || kind == 'unresolved') continue;

        final gift =
            (code['giftRefId'] ?? code['giftMementoId']) as String?;
        if (gift == null) continue; // a currency gift, nothing to link

        final resolved = switch (kind) {
          'facility' => facilityIds.contains(gift),
          'memento' => mementoIds.contains(gift),
          _ => mementoIds.contains(gift) || facilityIds.contains(gift),
        };
        if (!resolved) unlinkable.add('${code['code']} -> $gift ($kind)');
      }

      expect(unlinkable, isEmpty,
          reason: '${unlinkable.length} of ${codes.length} codes name a gift '
              'the page cannot resolve, so the player cannot tick it off: '
              '${unlinkable.take(4).toList()}');
    });

    test("the codes marked 'unresolved' are still exactly two", () {
      // If the data ever grows a third, it is worth looking at rather than
      // quietly shipping another untickable gift.
      final unresolved = readJsonList('assets/data/redemption_codes.json')
          .where((c) => c['giftKind'] == 'unresolved')
          .map((c) => '${c['code']} -> '
              '${c['giftRefId'] ?? c['giftMementoId']}')
          .toList()
        ..sort();

      expect(unresolved, <String>[
        'MOONFESTIVAL -> osmanthus_hanging_ornament',
        'SWEETLOVEAR -> gift_teddy_bear_2',
      ]);
    });
  });

  group('bucket agreement between a page and its checkbox', () {
    test('a customer checked on the customers page reads as checked '
        'everywhere', () async {
      final store = UnlockedStore.instance;
      store.debugResetForTest();
      await store.init();
      addTearDown(store.debugResetForTest);

      // CustomersPage, CustomerDetailPage, BoothOwnersPage, BandPage,
      // GlobalSearchPage and CompletionService must all use 'customers'.
      await store.setUnlocked('customers', 'white_bunny', true);
      expect(store.isUnlocked('customers', 'white_bunny'), isTrue);
      expect(store.isUnlocked('customer', 'white_bunny'), isFalse,
          reason: 'the legacy singular bucket must stay empty; a page that '
              'writes to it becomes invisible to the completion page');
    });

    test('a facility checked in a scene reads as checked from a cross-link',
        () async {
      final store = UnlockedStore.instance;
      store.debugResetForTest();
      await store.init();
      addTearDown(store.debugResetForTest);

      await store.setUnlocked('facility', 'stone_bowl', true);
      expect(store.isUnlocked('facility', 'stone_bowl'), isTrue);
      expect(store.isUnlocked('facility_purchased', 'stone_bowl'), isFalse);
    });

    test('a search hit knows which of the two facility buckets it belongs to',
        () async {
      // Facilities are split across two buckets by area, and global search
      // lists both kinds together. It used to write 'facility' for every hit,
      // so ticking a courtyard facility from search landed in a set the
      // Courtyard page and the completion percentage never read.
      final hits = await SearchIndex.instance.search('tree house');
      final simpleTreeHouse = hits.firstWhere(
        (h) => h.type == HitType.facility && h.id == 'simple_tree_house',
      );
      expect(simpleTreeHouse.bucket, ProgressTypes.courtyardFacility);
      expect(simpleTreeHouse.subtitle, 'Pet Yard');

      final sceneHits = await SearchIndex.instance.search('stone bowl');
      final stoneBowl = sceneHits.firstWhere(
        (h) => h.type == HitType.facility && h.id == 'stone_bowl',
      );
      expect(stoneBowl.bucket, ProgressTypes.facility);
    });

    test('the bucket a facility area maps to', () {
      for (final area in FacilityArea.values) {
        final bucket = ProgressTypes.facilityBucketFor(area.name);
        expect(
          bucket,
          area.name.startsWith('courtyard')
              ? ProgressTypes.courtyardFacility
              : ProgressTypes.facility,
          reason: '${area.name} is tracked in the wrong bucket',
        );
      }
    });
  });
}
