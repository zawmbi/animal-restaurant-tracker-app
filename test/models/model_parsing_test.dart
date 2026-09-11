// Every model is parsed against the real shipped asset, not a hand-written
// fixture, so a scrape that changes a field's type or drops a required key
// fails here instead of throwing inside a FutureBuilder in front of a player.
//
// Several fromJson factories use hard casts (`j['id'] as String`,
// `j['earnedStars'] as int?`). A hard cast on data that came from a wiki
// scrape is a crash waiting for the next scrape, so each of those is exercised
// over the entire file rather than over one row.
//
// Pure Dart: assets are read with dart:io, no rootBundle, no isolates.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/battle_pass/model/battle_pass.dart';
import 'package:animal_restaurant_tracker/features/courtyard/data/courtyard_facilities.dart';
import 'package:animal_restaurant_tracker/features/customers/model/customer.dart';
import 'package:animal_restaurant_tracker/features/customers/model/memento.dart';
import 'package:animal_restaurant_tracker/features/customers/model/poster.dart';
import 'package:animal_restaurant_tracker/features/dishes/model/dish.dart';
import 'package:animal_restaurant_tracker/features/economy/model/income.dart';
import 'package:animal_restaurant_tracker/features/facilities/model/facility.dart';
import 'package:animal_restaurant_tracker/features/letters/model/letter.dart';
import 'package:animal_restaurant_tracker/features/mementos/ui/mementos_page.dart';
import 'package:animal_restaurant_tracker/features/movies/model/movie.dart';
import 'package:animal_restaurant_tracker/features/pets/model/pet.dart';
import 'package:animal_restaurant_tracker/features/staff/model/staff_member.dart';

import '../support/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer', () {
    final rows = readJsonList('assets/data/customers.json');

    test('every row parses', () {
      for (final row in rows) {
        expect(() => Customer.fromJson(row), returnsNormally,
            reason: 'customer ${row['id']} failed to parse');
      }
    });

    test('613 customers, all with a non-empty id and name', () {
      final customers = rows.map(Customer.fromJson).toList();
      expect(customers.length, 613);
      for (final c in customers) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
      }
    });

    test('ids are unique', () {
      final ids = rows.map((r) => r['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('a row with every optional field missing still parses', () {
      final bare = Customer.fromJson(<String, dynamic>{'id': 'x'});
      expect(bare.name, '');
      expect(bare.customerDescription, '');
      expect(bare.tags, isEmpty);
      expect(bare.dishesOrderedIds, isEmpty);
      expect(bare.mementos, isEmpty);
      expect(bare.livesIn, isNull);
      expect(bare.appearanceWeight, isNull);
      expect(bare.requirements, isNull);
      expect(bare.boothOwner, isNull);
      expect(bare.performer, isNull);
    });

    test('explicit nulls parse the same as missing keys', () {
      final nulled = Customer.fromJson(<String, dynamic>{
        'id': 'x',
        'name': null,
        'tags': null,
        'livesIn': null,
        'appearanceWeight': null,
        'requirements': null,
        'mementos': null,
        'boothOwner': null,
        'performer': null,
        'requiredFoodId': null,
        'dishesOrderedIds': null,
      });
      expect(nulled.name, '');
      expect(nulled.tags, isEmpty);
      expect(nulled.appearanceWeight, isNull);
      expect(nulled.requirements, isNull);
    });

    test("the star requirement is read from 'rating' as well as "
        "'requiredStars'", () {
      final fromRating = Customer.fromJson(<String, dynamic>{
        'id': 'x',
        'requirements': <String, dynamic>{'rating': 920},
      });
      expect(fromRating.requirements!.requiredStars, 920);

      final fromRequired = Customer.fromJson(<String, dynamic>{
        'id': 'x',
        'requirements': <String, dynamic>{'requiredStars': 9},
      });
      expect(fromRequired.requirements!.requiredStars, 9);
    });

    test('flowers are their own requirement slot, never facilities', () {
      final flowerIds = <String>{
        for (final f in readJsonList('assets/data/flowers.json'))
          f['id'] as String,
      };
      for (final row in rows) {
        final c = Customer.fromJson(row);
        final req = c.requirements;
        if (req == null) continue;
        for (final id in req.facilities) {
          expect(flowerIds.contains(id), isFalse,
              reason: 'flower "$id" is sitting in ${c.id}\'s '
                  'requirements.facilities; it renders as a facility chip and '
                  'links to a page that cannot resolve it');
        }
      }
    });

    test('a performer block keeps its earnings, duration and links', () {
      final performers = rows
          .map(Customer.fromJson)
          .where((c) => c.performer != null)
          .toList();
      expect(performers.length, 61);

      final blank = performers
          .where((c) =>
              c.performer!.baseEarnings == null ||
              c.performer!.baseEarnings!.amountPerMinute == 0 ||
              c.performer!.showDurationMinutes == null)
          .map((c) => c.id)
          .toList();

      expect(blank, isEmpty,
          reason: 'these performers show a blank Base Earnings / Show Duration '
              'on their customer page even though performer_income.json has '
              'the numbers: $blank');
    });
  });

  group('Memento', () {
    final rows = readJsonList('assets/data/mementos.json');

    test('every row parses', () {
      for (final row in rows) {
        expect(() => Memento.fromJson(row), returnsNormally,
            reason: 'memento ${row['id']} failed to parse');
      }
    });

    test('1,184 mementos with unique ids', () {
      expect(rows.length, 1184);
      final ids = rows.map((r) => r['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('a row with only id and name parses', () {
      final bare = Memento.fromJson(<String, dynamic>{'id': 'x', 'name': 'X'});
      expect(bare.earnedStars, 0);
      expect(bare.requirement, '');
      expect(bare.description, '');
      expect(bare.tags, isEmpty);
      expect(bare.hidden, isFalse);
      expect(bare.equips, isEmpty);
      expect(bare.shareReward, isNull);
    });

    test('earnedStars is always an int in the data, because the cast is hard',
        () {
      // `j['earnedStars'] as int?` throws on a double. A scrape that writes
      // 15.0 instead of 15 would take down every memento page at once.
      for (final row in rows) {
        final raw = row['earnedStars'];
        expect(raw == null || raw is int, isTrue,
            reason: 'memento ${row['id']} has earnedStars of type '
                '${raw.runtimeType}');
      }
    });

    test('the Dress-Up tab has something in it', () {
      // The tab is keyed off MementoEntry.isWearable, which reads `equips`.
      // It used to filter on 'dress_up' / 'wearable' tags, which no memento
      // has ever carried, so the tab was permanently empty while 553 rows
      // said in `equips` exactly which staff could wear them.
      final tagged = rows.where((r) {
        final tags = (r['tags'] as List? ?? const <dynamic>[]).cast<String>();
        return tags.contains('dress_up') || tags.contains('wearable');
      }).length;
      final withEquips = rows
          .where((r) => (r['equips'] as List? ?? const []).isNotEmpty)
          .length;

      expect(withEquips, greaterThan(0),
          reason: 'nothing would land on the Dress-Up tab');
      expect(tagged, 0,
          reason: 'if a dress-up tag ever does appear, isWearable already '
              'honours it — this is only here to record that today the tags '
              'are not the source of truth');
    });

    test('every tag chip the page offers matches something', () {
      // The chips feed `includeTags`, a tag filter, so a chip naming something
      // that is not a tag empties the list. 'hidden' was exactly that: hidden
      // is a top-level field, and the chip found 0 of the 286 rows that carry
      // it. It was dropped, and the Hidden dropdown reads the field.
      final tagCounts = <String, int>{};
      for (final r in rows) {
        for (final t in (r['tags'] as List? ?? const <dynamic>[])) {
          tagCounts[t as String] = (tagCounts[t] ?? 0) + 1;
        }
      }

      final dead = MementosPage.commonTags
          .where((t) => (tagCounts[t] ?? 0) == 0)
          .toList();
      expect(dead, isEmpty,
          reason: 'these chips filter the list down to nothing: $dead');

      expect(tagCounts['hidden'] ?? 0, 0,
          reason: 'if hidden ever becomes a real tag, the chip can come back');
      expect(rows.where((r) => r['hidden'] == true).length, greaterThan(0),
          reason: 'the Hidden dropdown reads this field');
    });
  });

  group('Facility', () {
    test('every row of every shard parses', () {
      for (final entry in facilityShardsByArea.entries) {
        for (final shard in entry.value) {
          final rows = readJsonList('assets/data/facilities_jsons/$shard');
          for (final row in rows) {
            expect(() => Facility.fromJson(row), returnsNormally,
                reason: '$shard: facility ${row['id']} failed to parse');
          }
        }
      }
    });

    test('2,193 facilities across the scenes the Facilities page shows', () {
      // 2,193 rows and 2,193 unique ids. It used to be 2,191 unique out of
      // 2,193, because 'star_gazing' and 'christmas_long_table' each named two
      // different facilities in two different scenes — one key in the
      // 'facility' bucket, so ticking one ticked the other and the denominator
      // was two short. Both are area-qualified now.
      final ids = <String>{};
      var rows = 0;
      for (final area in facilitySceneAreas) {
        for (final row in facilityRowsForArea(area)) {
          rows++;
          ids.add(row['id'] as String);
        }
      }
      expect(ids.length, 2193);
      expect(ids.length, rows,
          reason: 'two rows sharing an id share one checkbox');
    });

    test('1,336 courtyard facilities', () {
      expect(facilityRowsForArea('courtyard').length, 1336);
    });

    test('a storageIncrease effect without a storageKind is rejected', () {
      expect(
        () => Facility.fromJson(<String, dynamic>{
          'id': 'x',
          'name': 'X',
          'area': 'takeout',
          'group': 'G',
          'effects': <dynamic>[
            <String, dynamic>{'type': 'storageIncrease', 'amount': 30},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('an unknown area is rejected rather than silently bucketed', () {
      expect(
        () => Facility.fromJson(<String, dynamic>{
          'id': 'x',
          'name': 'X',
          'area': 'basement',
          'group': 'G',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('a facility with no price and no effects parses as free', () {
      final free = Facility.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'X',
        'area': 'restaurant',
        'group': 'G',
      });
      expect(free.price, isEmpty);
      expect(free.effects, isEmpty);
      expect(free.requiredStars, isNull);
      expect(free.description, isNull);
      expect(free.series, isNull);
    });

    test('currency icon paths point at files that exist', () {
      // The enum names are plural, the assets are singular; getting this wrong
      // is how plates.png and diamonds.png ended up being requested.
      const expected = <MoneyCurrency, String>{
        MoneyCurrency.cod: 'assets/images/cod.png',
        MoneyCurrency.plates: 'assets/images/plate.png',
        MoneyCurrency.bells: 'assets/images/bell.png',
        MoneyCurrency.film: 'assets/images/film.png',
        MoneyCurrency.diamonds: 'assets/images/diamond.png',
      };
      expected.forEach((currency, path) {
        expect(currency.assetPath, path);
      });
    });
  });

  group('CourtyardFacility', () {
    test('every courtyard row parses', () {
      for (final row in readJsonList(
          'assets/data/facilities_jsons/courtyard_facilities.json')) {
        expect(() => CourtyardFacility.fromJson(row), returnsNormally,
            reason: 'courtyard facility ${row['id']} failed to parse');
      }
    });

    test('every facility has a group, because the page keys tabs off it', () {
      for (final row in readJsonList(
          'assets/data/facilities_jsons/courtyard_facilities.json')) {
        expect(row['group'], isA<String>(),
            reason: 'courtyard facility ${row['id']} has no group');
      }
    });
  });

  group('StaffMember', () {
    final rows = readJsonList('assets/data/staff.json');

    test('all 16 staff parse', () {
      expect(rows.length, 16);
      for (final row in rows) {
        expect(() => StaffMember.fromJson(row), returnsNormally,
            reason: 'staff ${row['id']} failed to parse');
      }
    });

    test('a staff member with no wearables or raises parses', () {
      final bare = StaffMember.fromJson(
          <String, dynamic>{'id': 'x', 'name': 'X'});
      expect(bare.wearableMementos, isEmpty);
      expect(bare.raiseUpgrades, isEmpty);
      expect(bare.series, isNull);
      expect(bare.blurb, isNull);
    });

    test('every wearable memento resolves to a real memento', () {
      final mementoIds = <String>{
        for (final m in readJsonList('assets/data/mementos.json'))
          m['id'] as String,
      };

      // 'sleepy_little_bear' is listed as one of Meow's wearables and is also
      // a Fantastical Party super reward, but it is typed there as a facility
      // and exists in neither registry. Rather than invent a memento row, the
      // staff page renders that one row untappable (see StaffDetailPage's
      // `resolves`). Everything else must resolve: an id that does not is a
      // chip that looks live and goes nowhere.
      const knownMissing = <String>{'sleepy_little_bear'};

      final unresolved = <String>{};
      for (final row in rows) {
        for (final w in StaffMember.fromJson(row).wearableMementos) {
          if (!mementoIds.contains(w.mementoId) &&
              !knownMissing.contains(w.mementoId)) {
            unresolved.add(w.mementoId);
          }
        }
      }
      expect(unresolved, isEmpty,
          reason: 'these chips open nothing when tapped: $unresolved');
    });

    test('the raise ladder is complete and in order', () {
      for (final row in rows) {
        final staff = StaffMember.fromJson(row);
        if (staff.raiseUpgrades.isEmpty) continue;
        final levels = staff.raiseUpgrades.map((u) => u.level).toList();
        expect(levels, orderedEquals(List<int>.generate(levels.length, (i) => i)),
            reason: '${staff.id} raise levels are not 0..n in order: $levels');
      }
    });
  });

  group('BattlePass', () {
    const passIds = <String>[
      'deep_sea_ballad',
      'fantastical_party',
      'midsummer_birdsong',
      'slumberous_nights',
    ];

    test('every pass parses and its id matches its filename', () {
      for (final id in passIds) {
        final raw = readJsonMap('assets/data/battle_passes/$id.json');
        final pass = BattlePass.fromJson(raw);
        expect(pass.id, id,
            reason: 'BattlePassRepository keys assets by id; a mismatch means '
                'byId() hands back the wrong pass');
      }
    });

    test('573 tiers in total, matching the completion denominator', () {
      var tiers = 0;
      for (final id in passIds) {
        final pass =
            BattlePass.fromJson(readJsonMap('assets/data/battle_passes/$id.json'));
        for (final phase in pass.phases) {
          tiers += phase.tiers.length;
        }
      }
      expect(tiers, 573);
    });

    test('no reward falls through to the text type by accident', () {
      // BattlePassReward._parseType has a `default:` that returns `text`, so an
      // unknown type is silently rendered as `r.text ?? 'Info'`. Asking the
      // parser rather than restating its cases means a type added to the JSON
      // fails here until the parser learns it — which is how the 'movie'
      // fragments were found rendering as "Info".
      bool parses(String type) =>
          type == 'text' ||
          BattlePassReward.fromJson(<String, dynamic>{'type': type}).type !=
              BattlePassRewardType.text;

      final unknown = <String>{};
      for (final id in passIds) {
        final raw = readJsonMap('assets/data/battle_passes/$id.json');
        for (final phase in (raw['phases'] as List).cast<Map>()) {
          for (final tier in (phase['tiers'] as List).cast<Map>()) {
            for (final key in <String>['normalRewards', 'superRewards']) {
              for (final reward
                  in (tier[key] as List? ?? const <dynamic>[]).cast<Map>()) {
                final type = reward['type'] as String;
                if (!parses(type)) unknown.add(type);
              }
            }
          }
        }
      }
      expect(unknown, isEmpty,
          reason: 'rewards of type $unknown parse as BattlePassRewardType.text '
              'with a null text, so the reward box reads "Info"');
    });

    test('a reward with no id or amount still parses', () {
      final reward =
          BattlePassReward.fromJson(<String, dynamic>{'type': 'text'});
      expect(reward.type, BattlePassRewardType.text);
      expect(reward.id, isNull);
      expect(reward.amount, isNull);
    });

    test('a phase with no dates or note parses', () {
      final phase = BattlePassPhase.fromJson(<String, dynamic>{
        'id': 'phase_1',
        'name': 'Phase 1',
      });
      expect(phase.start, '');
      expect(phase.end, '');
      expect(phase.completionNote, '');
      expect(phase.tiers, isEmpty);
    });
  });

  group('Dish', () {
    final rows = readJsonList('assets/data/dishes.json');

    test('every row parses and ids are unique', () {
      for (final row in rows) {
        expect(() => Dish.fromJson(row), returnsNormally,
            reason: 'dish ${row['id']} failed to parse');
      }
      final ids = rows.map((r) => r['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('ids are slugs and names are display text — they are never the same',
        () {
      // This is why passing a dish NAME where an id is expected fails: the
      // lookup lowercases but does not slugify.
      for (final row in rows) {
        expect(row['id'], isNot(row['name']));
      }
    });
  });

  group('Letter', () {
    final rows = readJsonList('assets/data/letters.json');

    test('all 257 letters parse', () {
      expect(rows.length, 257);
      for (final row in rows) {
        expect(() => Letter.fromJson(row), returnsNormally,
            reason: 'letter ${row['id']} failed to parse');
      }
    });

    test('earnedStars is text, not a number, for every letter', () {
      // Letter.earnedStars is a String? because the data holds '+60' and
      // 'Rating+90'. A scrape that writes a number would crash the cast.
      for (final row in rows) {
        final raw = row['earnedStars'];
        expect(raw == null || raw is String, isTrue,
            reason: 'letter ${row['id']} earnedStars is ${raw.runtimeType}');
      }
    });

    test('every combination slot is present and a string', () {
      // LetterCombination.fromJson casts all three slots without a fallback.
      for (final row in rows) {
        for (final combo
            in (row['combinations'] as List? ?? const <dynamic>[]).cast<Map>()) {
          for (final slot in <String>['slot1', 'slot2', 'slot3']) {
            expect(combo[slot], isA<String>(),
                reason: 'letter ${row['id']} combination $slot is '
                    '${combo[slot].runtimeType}');
          }
        }
      }
    });

    test('a letter with only id and name parses', () {
      final bare = Letter.fromJson(<String, dynamic>{'id': 'x', 'name': 'X'});
      expect(bare.combinations, isEmpty);
      expect(bare.series, isNull);
      expect(bare.description, isNull);
    });
  });

  group('Poster', () {
    final rows = readJsonList('assets/data/posters.json');

    test('all 155 posters parse', () {
      expect(rows.length, 155);
      for (final row in rows) {
        expect(() => Poster.fromJson(row), returnsNormally,
            reason: 'poster ${row['id']} failed to parse');
      }
    });

    test('a poster with no requirements block gets an empty one, not null', () {
      final bare = Poster.fromJson(<String, dynamic>{'id': 'x'});
      expect(bare.requirements.hasAny, isFalse);
      expect(bare.name, '');
      expect(bare.earningIncreasePercent, 0);
    });

    test('requiredPerformerIds and requirements.customers agree', () {
      // Both slots hold the same performers; a page that reads one and a
      // calculator that reads the other must not disagree.
      for (final row in rows) {
        final poster = Poster.fromJson(row);
        expect(poster.requiredPerformerIds.toSet(),
            poster.requirements.customers.toSet(),
            reason: 'poster ${poster.id} lists different performers in its two '
                'slots');
      }
    });
  });

  group('Movie', () {
    final rows = readJsonList('assets/data/movies.json');

    test('every movie parses and act keys are unique app-wide', () {
      final keys = <String>{};
      var acts = 0;
      for (final row in rows) {
        final movie = Movie.fromJson(row);
        for (final key in movie.allActKeys()) {
          expect(keys.add(key), isTrue, reason: 'duplicate act key "$key"');
          acts++;
        }
      }
      expect(acts, 198);
    });

    test('act keys are 1-based and shaped as the store expects', () {
      final movie = Movie.fromJson(<String, dynamic>{
        'id': 'daydream',
        'name': 'Daydream',
        'actCount': 4,
      });
      expect(movie.allActKeys(), <String>[
        'movie:daydream:act:1',
        'movie:daydream:act:2',
        'movie:daydream:act:3',
        'movie:daydream:act:4',
      ]);
    });

    test('a movie with no reward parses', () {
      final movie = Movie.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'X',
        'actCount': 1,
      });
      expect(movie.reward, isNull);
    });
  });

  group('PetsData', () {
    test('pets.json parses into 17 pets, 6 rooms and 9 photo tasks', () {
      final data = PetsData.fromJson(readJsonMap('assets/data/pets.json'));
      expect(data.pets.length, 17);
      expect(data.rooms.length, 6);
      expect(data.photoTasks.length, 9);
    });

    test('the pets category denominator is 49', () {
      final data = PetsData.fromJson(readJsonMap('assets/data/pets.json'));
      // owned + mature for each pet, plus rooms, plus photo tasks.
      final total = data.pets.length * 2 + data.rooms.length +
          data.photoTasks.length;
      expect(total, 49);
    });

    test('every photo task references pets that exist', () {
      final data = PetsData.fromJson(readJsonMap('assets/data/pets.json'));
      final petIds = data.pets.map((p) => p.id).toSet();
      for (final task in data.photoTasks) {
        for (final id in task.pets) {
          expect(petIds, contains(id),
              reason: 'photo task ${task.id} names pet "$id"');
        }
      }
    });
  });

  group('IncomeEntry', () {
    final root = readJsonMap('assets/data/income.json');

    test('every row of income.json parses into a known channel', () {
      final facilities = Map<String, dynamic>.from(root['facilities'] as Map);
      final unknown = <String>{};
      var parsed = 0;
      facilities.forEach((facilityId, rows) {
        for (final raw in (rows as List).cast<Map>()) {
          final entry =
              IncomeEntry.tryFromJson(Map<String, dynamic>.from(raw));
          if (entry == null) {
            unknown.add(raw['channel'].toString());
          } else {
            parsed++;
          }
        }
      });
      expect(unknown, isEmpty,
          reason: 'these channels are in the data but not in IncomeChannel, so '
              'their income is silently dropped: $unknown');
      expect(parsed, greaterThan(2500));
    });

    test('an unknown channel returns null instead of throwing', () {
      expect(
        IncomeEntry.tryFromJson(<String, dynamic>{'channel': 'not_a_channel'}),
        isNull,
      );
    });

    test('a fixed amount reads as a zero-width range', () {
      final entry = IncomeEntry.tryFromJson(<String, dynamic>{
        'channel': 'tipPerMinute',
        'currency': 'cod',
        'amount': 28,
      })!;
      expect(entry.minAmount, 28);
      expect(entry.maxAmount, 28);
      expect(entry.range.isExact, isTrue);
    });

    test('a min/max row keeps both ends', () {
      final entry = IncomeEntry.tryFromJson(<String, dynamic>{
        'channel': 'codPerGather',
        'currency': 'cod',
        'min': 95,
        'max': 4800,
      })!;
      expect(entry.minAmount, 95);
      expect(entry.maxAmount, 4800);
      expect(entry.range.isExact, isFalse);
      expect(entry.range.mid, (95 + 4800) / 2);
    });

    test('a non-money channel parses with a null currency', () {
      final entry = IncomeEntry.tryFromJson(<String, dynamic>{
        'channel': 'cookingEfficiencyPercent',
        'amount': 10,
      })!;
      expect(entry.currency, isNull);
    });

    test('every codPerSeconds row carries the period it is measured over', () {
      // Without `seconds` the calculator contributes nothing, so the facility
      // silently pays zero rather than 28,800 cod/h.
      final facilities = Map<String, dynamic>.from(root['facilities'] as Map);
      final missing = <String>[];
      facilities.forEach((facilityId, rows) {
        for (final raw in (rows as List).cast<Map>()) {
          if (raw['channel'] == 'codPerSeconds' && raw['seconds'] == null) {
            missing.add(facilityId);
          }
        }
      });
      expect(missing, isEmpty);
    });
  });

  group('PerformerIncome', () {
    final root = readJsonMap('assets/data/performer_income.json');

    test('all 61 performers parse', () {
      final performers = Map<String, dynamic>.from(root['performers'] as Map);
      expect(performers.length, 61);
      performers.forEach((id, value) {
        final income = PerformerIncome.tryFromJson(
            id, Map<String, dynamic>.from(value as Map));
        expect(income, isNotNull, reason: 'performer $id failed to parse');
      });
    });

    test('customers.json agrees with it, performer for performer', () {
      // The same numbers live in both files: the customer page reads the
      // `performer` block, the earnings pages read this one. 60 of the 61
      // blocks used to be stubs — a null duration, a null amount and 'film'
      // hardcoded as the currency even for the cod performers — so the
      // customer page showed a blank show and the wrong currency. They are
      // filled in now, and this keeps the two from drifting apart again.
      final performers = Map<String, dynamic>.from(root['performers'] as Map);
      final customers = readJsonList('assets/data/customers.json')
          .map(Customer.fromJson)
          .where((c) => c.performer != null)
          .toList();

      expect(customers.length, performers.length);

      final disagree = <String>[];
      for (final c in customers) {
        final raw = performers[c.id];
        if (raw == null) {
          disagree.add('${c.id}: no row in performer_income.json');
          continue;
        }
        final income =
            PerformerIncome.tryFromJson(c.id, Map<String, dynamic>.from(raw));
        final p = c.performer!;
        if (income == null) continue; // covered by the test above

        if (p.showDurationMinutes != income.showDurationMinutes) {
          disagree.add('${c.id}: show ${p.showDurationMinutes} vs '
              '${income.showDurationMinutes}');
        }
        if (p.baseEarnings?.amountPerMinute != income.amountPerMinute) {
          disagree.add('${c.id}: per minute '
              '${p.baseEarnings?.amountPerMinute} vs ${income.amountPerMinute}');
        }
        if (p.baseEarnings?.currency != income.currency.name) {
          disagree.add('${c.id}: currency ${p.baseEarnings?.currency} vs '
              '${income.currency.name}');
        }
        if ((p.band ?? '') != (income.band ?? '')) {
          disagree.add('${c.id}: band ${p.band} vs ${income.band}');
        }
      }

      expect(disagree, isEmpty,
          reason: 'the customer page and the earnings pages would print '
              'different numbers for the same performer: $disagree');
    });

    test('a row missing its currency or duration returns null, not a zero', () {
      expect(
        PerformerIncome.tryFromJson('x', <String, dynamic>{
          'amountPerMinute': 10,
          'showDurationMinutes': 30,
        }),
        isNull,
      );
      expect(
        PerformerIncome.tryFromJson('x', <String, dynamic>{
          'currency': 'film',
          'showDurationMinutes': 30,
        }),
        isNull,
      );
    });

    test('worked example: Cutie White Bunny pays 300 film per show', () {
      final performers = Map<String, dynamic>.from(root['performers'] as Map);
      final bunny = PerformerIncome.tryFromJson(
        'cutie_white_bunny',
        Map<String, dynamic>.from(performers['cutie_white_bunny'] as Map),
      )!;
      expect(bunny.amountPerMinute, 10);
      expect(bunny.showDurationMinutes, 30);
      expect(bunny.perShow, 300);
    });

    test('worked example: the two best single shows are Ball Lightning', () {
      final performers = Map<String, dynamic>.from(root['performers'] as Map);
      PerformerIncome load(String id) => PerformerIncome.tryFromJson(
          id, Map<String, dynamic>.from(performers[id] as Map))!;

      final bassist = load('bassist_brown_wolf');
      expect(bassist.band, 'Ball Lightning');
      expect(bassist.perShow, 16 * 55);

      final dj = load('dj_wolf');
      expect(dj.band, 'Ball Lightning');
      expect(dj.perShow, 1200 * 55);
    });
  });
}
