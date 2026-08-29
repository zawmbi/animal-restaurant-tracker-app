// "Information being related and linked together": every id a detail page
// renders as a tappable chip has to resolve to the entity of the right KIND,
// and the checkbox next to it has to read the same bucket the owning page
// writes.
//
// These use the real repositories, so they need `flutter test` and its asset
// bundle. Firebase is never touched.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/customers/data/customers_repository.dart';
import 'package:animal_restaurant_tracker/features/dishes/data/dishes_repository.dart';
import 'package:animal_restaurant_tracker/features/facilities/data/facilities_repository.dart';
import 'package:animal_restaurant_tracker/features/letters/data/letters_repository.dart';
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
      // The chip fills when isUnlocked('dish', <the same value>), but the
      // dishes page stores Dish.id. A name is never an id.
      final customers = await CustomersRepository.instance.all();
      final dishIds = <String>{
        for (final d in await DishesRepository.instance.all()) d.id,
      };

      final unmatched = <String>{};
      for (final customer in customers) {
        for (final recipe in customer.requirements?.recipes ?? const <String>[]) {
          if (!dishIds.contains(recipe)) unmatched.add(recipe);
        }
      }

      expect(unmatched, isEmpty,
          reason: '${unmatched.length} recipe chips can never show as owned: '
              'they are compared against the "dish" bucket, which holds ids');
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
    test('every facility chip resolves to a facility', () async {
      final customers = await CustomersRepository.instance.all();
      final repo = FacilitiesRepository.instance;

      final dead = <String>{};
      for (final customer in customers) {
        for (final id in customer.requirements?.facilities ?? const <String>[]) {
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
    test('every code with a gift can be linked and checked off', () {
      // RedemptionCodesPage only looks its gift up in the memento index, and
      // its model drops giftKind and giftRefId entirely — so a facility gift
      // renders as plain text with a disabled checkbox.
      final codes = readJsonList('assets/data/redemption_codes.json');
      final mementoIds = <String>{
        for (final m in readJsonList('assets/data/mementos.json'))
          m['id'] as String,
      };

      final unlinkable = <String>[];
      for (final code in codes) {
        final gift = code['giftMementoId'] as String?;
        if (gift == null) continue; // a currency gift, nothing to link
        if (!mementoIds.contains(gift)) {
          unlinkable.add('${code['code']} -> $gift (${code['giftKind']})');
        }
      }

      expect(unlinkable, isEmpty,
          reason: '${unlinkable.length} of ${codes.length} codes name a gift '
              'the page cannot resolve, so the player cannot tick it off: '
              '${unlinkable.take(4).toList()}');
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
  });
}
