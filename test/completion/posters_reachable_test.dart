// All 155 posters counted toward overall completion while only six could be
// ticked: PosterDetailPage was reachable from one place — a performer's
// posterIds on the customer page — and exactly one of the 613 customers
// carries any. The other 149 were permanently unowned, capping the headline
// percentage at 98%.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/customers/data/customers_repository.dart';
import 'package:animal_restaurant_tracker/features/customers/data/posters_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the customer page alone reaches almost none of the posters', () async {
    // Pinning the reason the list page has to exist. If a future scrape gives
    // performers their posterIds, this number climbs and the comment above
    // stops being true — worth noticing.
    final customers = await CustomersRepository.instance.all();
    final viaCustomers = <String>{
      for (final c in customers) ...?c.performer?.posterIds,
    };

    final all = await PostersRepository.instance.all();
    expect(all, hasLength(155));
    expect(viaCustomers.length, lessThan(10),
        reason: 'reachable from a customer page: ${viaCustomers.length}');
  });

  test('every poster has an id the list page can tick', () async {
    final all = await PostersRepository.instance.all();
    final ids = all.map((p) => p.id).toList();

    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate poster ids');
    for (final p in all) {
      expect(p.id, isNotEmpty);
      expect(p.name, isNotEmpty, reason: '${p.id} would render a blank chip');
    }
  });
}
