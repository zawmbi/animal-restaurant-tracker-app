// Every customer has to be reachable by browsing, not just by searching.
//
// Eight of the 613 — Deer, Gloomy, White Shiba and five terrace regulars —
// carried only tags like `restaurant` or `terrace`, which none of the seven
// filtered tabs reads, and no season. They showed on the All tab and nowhere
// else, so a player working through the tabs would never see them.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/customers/data/customers_repository.dart';
import 'package:animal_restaurant_tracker/features/customers/model/customer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every customer appears on at least one tab besides All', () async {
    final repo = CustomersRepository.instance;
    final all = await repo.all();

    final reachable = <String>{};
    for (final c in await repo.regulars()) {
      reachable.add(c.id);
    }
    for (final c in await repo.seasonal()) {
      reachable.add(c.id);
    }
    for (final tag in CustomersRepository.tabTags) {
      if (tag == 'regular') continue; // covered by regulars()
      for (final c in await repo.withTag(tag)) {
        reachable.add(c.id);
      }
    }

    final orphans =
        all.where((c) => !reachable.contains(c.id)).map((c) => c.id).toList();
    expect(
      orphans,
      isEmpty,
      reason: 'only reachable from the All tab: ${orphans.join(', ')}',
    );
  });

  test('the Regular tab picks up the customers no other tab claims', () async {
    final repo = CustomersRepository.instance;
    final regulars = await repo.regulars();
    final tagged = await repo.withTag('regular');

    expect(regulars.length, greaterThan(tagged.length),
        reason: 'the fallback should add the untagged ones');

    final ids = regulars.map((c) => c.id).toSet();
    for (final id in const [
      'deer',
      'gloomy',
      'white_shiba',
      'bouncy_the_pika',
      'dobermann',
      'hoppy_the_pika',
      'mad_hatter',
      'sunny',
    ]) {
      expect(ids, contains(id), reason: '$id fell off the tabs again');
    }
  });

  test('the fallback does not steal customers from another tab', () async {
    final repo = CustomersRepository.instance;
    final regulars = await repo.regulars();

    for (final Customer c in regulars) {
      if (c.tags.contains('regular')) continue;
      // Anything here on the fallback must genuinely belong nowhere else.
      expect(c.season, isNull, reason: '${c.id} belongs on Seasonal');
      for (final tag in CustomersRepository.tabTags) {
        expect(c.tags, isNot(contains(tag)),
            reason: '${c.id} already has the $tag tab');
      }
    }
  });
}
