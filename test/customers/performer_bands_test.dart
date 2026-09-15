// Eleven performers keep their band at the top level of their row rather than
// under `performer`, so reading only the nested block dropped them out of
// their band entirely — Puff Planet listed 1 of its 4 members.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/customers/data/customers_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every performer-tagged customer has a performer block', () async {
    final all = await CustomersRepository.instance.all();
    final performers = all.where((c) => c.tags.contains('performer')).toList();

    expect(performers, hasLength(76));

    // Four are genuine stubs on the wiki with no performer data at all; the
    // rest must resolve, whichever spelling their row uses.
    final without =
        performers.where((c) => c.performer == null).map((c) => c.id).toList();
    expect(without, hasLength(4),
        reason: 'unexpectedly missing a performer block: ${without.join(', ')}');
  });

  test('the three flat-spelled bands are whole again', () async {
    final all = await CustomersRepository.instance.all();

    Iterable<String> members(String band) =>
        all.where((c) => c.performer?.band == band).map((c) => c.id);

    expect(members('Puff Planet'), hasLength(4));
    expect(members('Puff Planet'), contains('frosty_star'));
    expect(members('Lightseeker Ballet Troupe'), hasLength(4));
    expect(members('Aurora Puppet Club'), hasLength(4));
  });

  test('a nested performer block still wins', () async {
    final all = await CustomersRepository.instance.all();
    final minty = all.firstWhere((c) => c.id == 'minty_star');

    // minty_star has the proper nested shape; the fallback must not shadow it.
    expect(minty.performer, isNotNull);
    expect(minty.performer!.band, 'Puff Planet');
  });
}
