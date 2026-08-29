// The helpers that stop raw data keys reaching a player, plus the data facts
// that decide when prettifying an id is safe and when it is a lie.
//
// prettyId is fine for a slug that has no canonical display name (a memento
// *source*, say). It is NOT a substitute for looking a name up: 66 of the 556
// staff wearable mementos have a real name that prettyId cannot reproduce
// ("Baker's Hat", "Band-Aid", "Blueberries and Cream Hat"), and 1,358 of the
// 4,058 facilities are in the same position.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/shared/utils/display_names.dart';

import '../support/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prettyId', () {
    test('turns a slug into title case', () {
      expect(prettyId('hermit_crab'), 'Hermit Crab');
      expect(prettyId('white_bunny'), 'White Bunny');
      expect(prettyId('signature_store'), 'Signature Store');
    });

    test('leaves an already-spaced name alone', () {
      expect(prettyId('Hermit Crab'), 'Hermit Crab');
    });

    test('never leaves an underscore behind', () {
      for (final raw in <String>[
        'a_b_c',
        '__leading',
        'trailing__',
        'double__underscore',
      ]) {
        expect(prettyId(raw), isNot(contains('_')));
      }
    });

    test('an empty string stays empty rather than throwing', () {
      expect(prettyId(''), '');
    });

    test('a single word is capitalised', () {
      expect(prettyId('taiyaki'), 'Taiyaki');
    });
  });

  group('prettyCurrency', () {
    test('capitalises the lowercase data keys', () {
      expect(prettyCurrency('cod'), 'Cod');
      expect(prettyCurrency('plates'), 'Plates');
      expect(prettyCurrency('film'), 'Film');
      expect(prettyCurrency('bells'), 'Bells');
      expect(prettyCurrency('diamonds'), 'Diamonds');
    });

    test('every currency key that appears in the shipped data capitalises', () {
      final currencies = <String>{};
      for (final row in readJsonList('assets/data/dishes.json')) {
        for (final p in (row['price'] as List? ?? const <dynamic>[]).cast<Map>()) {
          if (p['currency'] != null) currencies.add(p['currency'].toString());
        }
      }
      for (final b
          in readJsonMap('assets/data/booth_owners.json').values.cast<Map>()) {
        for (final r
            in (b['incomeEvery5Min'] as List? ?? const <dynamic>[]).cast<Map>()) {
          if (r['currency'] != null) currencies.add(r['currency'].toString());
        }
      }
      expect(currencies, isNotEmpty);
      for (final c in currencies) {
        final pretty = prettyCurrency(c);
        expect(pretty[0], pretty[0].toUpperCase(),
            reason: '"$c" would print lowercase to a player');
      }
    });
  });

  group('when an id must be looked up rather than prettified', () {
    test('most facility names cannot be recovered from the id', () {
      final names = <String, String>{};
      for (final entry in facilityShardsByArea.entries) {
        for (final shard in entry.value) {
          for (final row
              in readJsonList('assets/data/facilities_jsons/$shard')) {
            names.putIfAbsent(row['id'] as String, () => row['name'] as String);
          }
        }
      }
      final wrong =
          names.entries.where((e) => prettyId(e.key) != e.value).length;
      expect(wrong, greaterThan(0),
          reason: 'if this ever reaches 0 the shortcut becomes safe; until '
              'then, any screen that prettifies a facility id prints a name '
              'the game does not use');
    });

    test('staff wearable memento names must come from mementos.json', () {
      final mementoNames = <String, String>{
        for (final m in readJsonList('assets/data/mementos.json'))
          m['id'] as String: m['name'] as String,
      };

      final wrong = <String>[];
      for (final s in readJsonList('assets/data/staff.json')) {
        for (final w
            in (s['wearableMementos'] as List? ?? const <dynamic>[]).cast<Map>()) {
          final id = w['mementoId'] as String;
          final real = mementoNames[id];
          if (real != null && prettyId(id) != real) wrong.add(id);
        }
      }

      final examples = <String>[
        for (final id in wrong.toSet().take(3))
          '$id renders as ${prettyId(id)} but is called ${mementoNames[id]}',
      ];
      expect(wrong, isEmpty,
          reason: 'StaffDetailPage titleizes the memento id instead of reading '
              'the memento name, so these chips print the wrong text: '
              '$examples');
    });
  });
}
