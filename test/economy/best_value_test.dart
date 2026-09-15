// income.json knows what 2,794 facilities pay and the shards know what they
// cost, and nothing joined the two — so "what should I buy next", the
// optimiser's whole question, had no answer anywhere in the app.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_restaurant_tracker/features/bank/data/bank_service.dart';
import 'package:animal_restaurant_tracker/features/economy/model/income.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    UnlockedStore.instance.debugResetForTest();
    await UnlockedStore.instance.init();
  });

  test('ranks unowned buffet facilities by income per cod', () async {
    final rows = await BankService().bestValue(IncomeChannel.buffetCodPerHour);

    expect(rows, isNotEmpty);
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i - 1].perCod, greaterThanOrEqualTo(rows[i].perCod),
          reason: 'ranking is not sorted at row $i');
    }
    for (final r in rows) {
      expect(r.codPrice, greaterThan(0));
      expect(r.amount, greaterThan(0));
      expect(r.perCod, r.amount / r.codPrice);
    }
  });

  test('the spread is wide enough that the ranking earns its place', () async {
    final rows =
        await BankService().bestValue(IncomeChannel.buffetCodPerHour, limit: 1000);
    expect(rows.length, greaterThan(20));

    final best = rows.first.perCod;
    final worst = rows.last.perCod;
    expect(best / worst, greaterThan(10),
        reason: 'if every buy were equivalent this screen would be pointless');
  });

  test('what you already own drops out', () async {
    final before = await BankService().bestValue(IncomeChannel.buffetCodPerHour);
    final top = before.first.facilityId;

    await UnlockedStore.instance.setUnlocked('facility', top, true);

    final after = await BankService().bestValue(IncomeChannel.buffetCodPerHour);
    expect(after.map((r) => r.facilityId), isNot(contains(top)));
  });

  test('facilities priced in film or diamonds are not ranked', () async {
    // Ranking them on the same scale would mean inventing an exchange rate.
    final rows =
        await BankService().bestValue(IncomeChannel.buffetCodPerHour, limit: 1000);
    for (final r in rows) {
      expect(r.codPrice, greaterThan(0));
    }
  });
}
