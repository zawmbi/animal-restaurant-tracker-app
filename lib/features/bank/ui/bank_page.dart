import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/currency.dart';
import '../../economy/model/economy_constants.dart';
import '../../economy/model/income.dart';
import '../../economy/model/money_bag.dart';
import '../data/bank_service.dart';
import '../data/terrace_customers.dart';

/// Bundles everything the bank page needs from a single async load.
class _BankData {
  final BankStats stats;
  final List<TerraceCustomer> terrace;
  const _BankData(this.stats, this.terrace);
}

class BankPage extends StatefulWidget {
  const BankPage({super.key});
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final _service = BankService();

  // Tip jar: how long the jar has been left to fill (in minutes).
  final _tipMinutesCtrl = TextEditingController(text: '60');

  // Apricat's raise level: she adds cod/min to the jar while sweeping.
  final _apricatLevelCtrl = TextEditingController();

  // Buffet: hours left to accumulate (1-12), and friends working part-time.
  final _buffetHoursCtrl = TextEditingController(text: '3');
  final _buffetFriendsCtrl = TextEditingController(text: '0');

  // Kitchen: Eggy's raise level drives his cod-per-60s pickup.
  final _eggyLevelCtrl = TextEditingController();

  // Buffet: Yolky's raise level drives his plates per 4 hours.
  final _yolkyLevelCtrl = TextEditingController();

  // Restaurant: purchases served in the window the player cares about.
  final _purchasesCtrl = TextEditingController();

  // Courtyard: gathers used.
  final _gathersCtrl = TextEditingController(text: '1');

  // Concert: the displayed poster's earning increase, in percent.
  final _posterPercentCtrl = TextEditingController();

  // Fishing pond: booths leased, and how long they are left running.
  final _boothsCtrl = TextEditingController(text: '1');
  final _boothMinutesCtrl = TextEditingController(text: '60');

  // Terrace: cod gifted per gather, as observed in the player's own game.
  final _terraceCodCtrl = TextEditingController();

  late Future<_BankData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BankData> _load() async {
    final stats = await _service.compute();
    final terrace = await TerraceCustomersRepository.instance.all();
    return _BankData(stats, terrace);
  }

  @override
  void dispose() {
    _tipMinutesCtrl.dispose();
    _apricatLevelCtrl.dispose();
    _buffetHoursCtrl.dispose();
    _buffetFriendsCtrl.dispose();
    _eggyLevelCtrl.dispose();
    _yolkyLevelCtrl.dispose();
    _purchasesCtrl.dispose();
    _gathersCtrl.dispose();
    _posterPercentCtrl.dispose();
    _boothsCtrl.dispose();
    _boothMinutesCtrl.dispose();
    _terraceCodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank')),
      body: FutureBuilder<_BankData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _errorCard('${snap.error}');
          }

          final data = snap.data!;
          final s = data.stats;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _coverageCard(context, s),
              const SizedBox(height: 12),
              _tipJarCard(context, s),
              const SizedBox(height: 12),
              _buffetCard(context, s),
              const SizedBox(height: 12),
              _platesCard(context, s),
              const SizedBox(height: 12),
              _activeCodCard(context, s),
              const SizedBox(height: 12),
              _purchaseCard(context, s),
              const SizedBox(height: 12),
              _courtyardGatherCard(context, s),
              const SizedBox(height: 12),
              _concertCard(context, s),
              const SizedBox(height: 12),
              _terraceCard(context, s, data.terrace),
              const SizedBox(height: 12),
              _takeoutCard(context, s),
              const SizedBox(height: 12),
              _fishingCard(context, s),
              const SizedBox(height: 12),
              _drawsCard(context, s),
              const SizedBox(height: 12),
              _sourcesCard(context, s),
            ],
          );
        },
      ),
    );
  }

  Widget _errorCard(String msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to load bank stats',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(msg),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Coverage

  Widget _coverageCard(BuildContext context, BankStats s) {
    return _card(
      context,
      icon: 'assets/images/star.png',
      title: 'What these numbers cover',
      children: [
        _kv('Facilities you own', _plain(_fmt(s.ownedFacilityCount))),
        _kv('…of those, ones that earn',
            _plain(_fmt(s.owned.facilitiesCounted))),
        _kv('Facilities in the game that earn',
            _plain(_fmt(s.facilitiesWithIncome))),
        const SizedBox(height: 8),
        Text(
          'Every effect below is summed across the facilities you have ticked '
          'off, because the game combines the effects of every unlocked '
          'facility whether or not it is the one on display. The Flowerbed is '
          'the documented exception and is not summed here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (s.owned.facilitiesCounted == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Nothing is ticked off yet, so the "you" column is zero. The '
              '"everything" figures show the ceiling.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- Tip Jar

  Widget _tipJarCard(BuildContext context, BankStats s) {
    final cap = s.owned.tipCapCod;
    final capAll = s.everything.tipCapCod;

    final apricat = s.staff['apricat'];
    final apricatLevel = _parseInt(_apricatLevelCtrl.text);
    final double apricatRate = (apricat != null && apricatLevel != null)
        ? (apricat.levelAt(apricatLevel)?.tipsPerMinute ?? 0.0)
        : 0.0;

    final facilityRate = s.owned.tipPerMinuteCod;
    final rate = facilityRate + apricatRate;
    final rateAll = s.everything.tipPerMinuteCod;

    double collectableAt(double minutes) => EarningsCalculator.tipsAfterMinutes(
          perMinute: rate,
          capacity: cap,
          minutes: minutes,
        );

    final double minutes =
        (_parseDouble(_tipMinutesCtrl.text) ?? 0.0).clamp(0.0, 1e9).toDouble();
    final answer = collectableAt(minutes);
    final answerWithAd = answer * EconomyConstants.tipJarAdMultiplier;

    final minutesToFill = EarningsCalculator.minutesToFillTipJar(
      perMinute: rate,
      capacity: cap,
    );

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Tip Jar',
      children: [
        _kv('Jar capacity', _amount(MoneyCurrency.cod, cap)),
        _kv('Fill rate from facilities',
            _rate(MoneyCurrency.cod, facilityRate, '/min')),
        if (apricatRate > 0)
          _kv('…plus Apricat sweeping',
              _rate(MoneyCurrency.cod, apricatRate, '/min')),
        _kv('Fill rate total', _rate(MoneyCurrency.cod, rate, '/min')),
        _kv('That is', _rate(MoneyCurrency.cod, rate * 60, '/h')),

        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _apricatLevelCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Apricat level',
                  hintText: apricat == null
                      ? '—'
                      : '0–${apricat.maxLevel}',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                apricat == null
                    ? 'Apricat data is missing from staff.json.'
                    : 'Apricat adds cod/min to the jar while she is sweeping, '
                        'then rests, so treat her line as the ceiling.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        Text('How much will the jar hold after…',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        _kv('1 minute', _amount(MoneyCurrency.cod, collectableAt(1))),
        _kv('1 hour', _amount(MoneyCurrency.cod, collectableAt(60))),
        _kv('6 hours', _amount(MoneyCurrency.cod, collectableAt(360))),
        _kv('12 hours', _amount(MoneyCurrency.cod, collectableAt(720))),
        _kv('24 hours', _amount(MoneyCurrency.cod, collectableAt(1440))),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: _tipMinutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _minutesLabel(minutes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _kv('Collectable', _amount(MoneyCurrency.cod, answer)),
        _kv('With ad (2×)', _amount(MoneyCurrency.cod, answerWithAd)),

        if (rate > 0 && cap > 0 && minutesToFill != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'The jar fills completely in ${_hoursText(minutesToFill / 60.0)} '
              'and then stops. Collecting more often than that wastes nothing; '
              'collecting less often does.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        if (capAll > cap)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${_fmt(capAll - cap)} capacity and '
              '+${_fmt(math.max(0, rateAll - facilityRate))} cod/min are still '
              'unbought.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Tips accrue online and offline and are limited by the jar, not by '
            'a clock. Only the Buffet has a 12-hour ceiling.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- Buffet

  Widget _buffetCard(BuildContext context, BankStats s) {
    final perHour = s.owned.buffetCodPerHour;
    final perHourAll = s.everything.buffetCodPerHour;

    final rawHours = _parseDouble(_buffetHoursCtrl.text) ?? 3.0;
    final double hours = rawHours.clamp(0.0, 24.0).toDouble();
    final int friends =
        (_parseInt(_buffetFriendsCtrl.text) ?? 0).clamp(0, 50).toInt();

    final base = EarningsCalculator.buffetAfterHours(
      perHour: perHour,
      hours: hours,
      friendsWorking: friends,
    );
    final adBonus = EarningsCalculator.buffetAdBonus(base);

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Buffet (offline income)',
      children: [
        if (perHour == 0)
          const Text('No buffet facility that earns cod is ticked off yet.')
        else ...[
          _kv('Buffet cod per hour', _rate(MoneyCurrency.cod, perHour, '/h')),
          _kv('12 hours (the cap)',
              _amount(MoneyCurrency.cod, perHour * 12)),

          const Divider(height: 24),

          Text('How much after…',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _kv('1 hour', _amount(MoneyCurrency.cod, perHour)),
          _kv('6 hours', _amount(MoneyCurrency.cod, perHour * 6)),
          _kv('12 hours', _amount(MoneyCurrency.cod, perHour * 12)),
          _kv('24 hours (still 12h of income)',
              _amount(MoneyCurrency.cod, perHour * 12)),

          const SizedBox(height: 12),

          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _buffetHoursCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Hours away',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _buffetFriendsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Friends working',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hours > 12
                      ? 'Counted as 12 h'
                      : '${hours.toStringAsFixed(1)} h',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Without ad', _amount(MoneyCurrency.cod, base)),
          _kv('Ad bonus (40%, max 1,000,000)',
              _amount(MoneyCurrency.cod, adBonus)),
          _kv('With ad', _amount(MoneyCurrency.cod, base + adBonus)),

          if (friends > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Each friend working adds 10% of your hourly rate, but only '
                'for their first 4 hours.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'The ad bonus stops improving once the buffet is holding '
              '${_fmt(EarningsCalculator.buffetAdBreakEvenCod())} cod — at '
              'your rate that is after '
              '${perHour > 0 ? _hoursText(EarningsCalculator.buffetAdBreakEvenCod() / perHour) : '—'}. '
              'Collect around then rather than waiting for the 12-hour mark.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],

        if (perHourAll > perHour)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '+${_fmt(perHourAll - perHour)} cod/h is still unbought across '
              'the conveyor belts, ice cream, sliding doors and wall hangings.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------- Plates

  Widget _platesCard(BuildContext context, BankStats s) {
    final perDay = s.owned.buffetPlatesPerDay;
    final perDayAll = s.everything.buffetPlatesPerDay;

    // Worked example - Yolky at raise 24 pays 140 plates per 4 hours and the
    // player's own shift pays a flat 200, so six cycles in a day come to
    // (200 + 140) * 6 = 2,040 plates, on top of whatever the Self-serve
    // Drinks and Time Clock facilities drop at the daily reset.
    final yolky = s.staff['yolky'];
    final yolkyLevel = _parseInt(_yolkyLevelCtrl.text);
    final double yolkyPer4h = (yolky != null && yolkyLevel != null)
        ? (yolky.levelAt(yolkyLevel)?.platesPer4Hours ?? 0.0)
        : 0.0;

    return _card(
      context,
      icon: 'assets/images/plate.png',
      title: 'Plates',
      children: [
        _kv('Self-serve Drinks + Time Clock, per day',
            _amount(MoneyCurrency.plates, perDay)),
        if (perDayAll > perDay)
          _kv('If you owned them all',
              _amount(MoneyCurrency.plates, perDayAll)),

        const Divider(height: 24),

        Text('Part-time work',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'You and Yolky can each work a friend\'s buffet once every 4 hours. '
          'Your own share is a flat 200 plates; Yolky\'s depends on his raise.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _yolkyLevelCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Yolky level',
                  hintText: yolky == null ? '—' : '0–${yolky.maxLevel}',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                yolky == null
                    ? 'Yolky data is missing from staff.json.'
                    : 'Up to 12 hours of Yolky\'s wages are held for you.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _kv(
            'You, per 4 h',
            _amount(MoneyCurrency.plates,
                EconomyConstants.buffetWorkPlayerPlatesPer4h.toDouble())),
        if (yolkyPer4h > 0)
          _kv('Yolky, per 4 h', _amount(MoneyCurrency.plates, yolkyPer4h)),
        _kv(
            'Both, six times a day',
            _amount(
                MoneyCurrency.plates,
                (EconomyConstants.buffetWorkPlayerPlatesPer4h.toDouble() +
                        yolkyPer4h) *
                    6)),

        const Divider(height: 24),
        _kv(
            'Facilities + work, per day',
            _amount(
                MoneyCurrency.plates,
                perDay +
                    (EconomyConstants.buffetWorkPlayerPlatesPer4h.toDouble() +
                            yolkyPer4h) *
                        6)),
        const SizedBox(height: 8),
        Text(
          'Not counted here: plates dropped by buffet customers, Get Together '
          'parties, Gachapon prizes and booth owners — the game publishes no '
          'rates for those. Booth owners have their own card below.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ---------------------------------------------------- Active (game open)

  Widget _activeCodCard(BuildContext context, BankStats s) {
    final perHour = s.owned.activeCodPerHour;
    final perHourAll = s.everything.activeCodPerHour;

    final eggy = s.staff['eggy'];
    final eggyLevel = _parseInt(_eggyLevelCtrl.text);
    final double eggyPer60s = (eggy != null && eggyLevel != null)
        ? (eggy.levelAt(eggyLevel)?.codPer60Seconds ?? 0.0)
        : 0.0;
    final eggyPerHour = eggyPer60s * 60;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Cod while the game is open',
      children: [
        Text(
          'Ovens, cabinets, counters, mailboxes, barbecues and the terrace '
          'snack counter drop cod every 30 seconds, but only while you are '
          'actually in the game and tapping them up.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _kv('From facilities', _rate(MoneyCurrency.cod, perHour, '/h')),
        _kv('Per 30 s drop', _amount(MoneyCurrency.cod, perHour / 120)),
        if (perHourAll > perHour)
          _kv('If you owned them all',
              _rate(MoneyCurrency.cod, perHourAll, '/h')),

        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _eggyLevelCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Eggy level',
                  hintText: eggy == null ? '—' : '0–${eggy.maxLevel}',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eggy == null
                    ? 'Eggy data is missing from staff.json.'
                    : 'Eggy never rests, so his rate runs the whole time the '
                        'kitchen is open.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (eggyPer60s > 0) ...[
          const SizedBox(height: 8),
          _kv('Eggy', _rate(MoneyCurrency.cod, eggyPer60s, '/60 s')),
          _kv('Eggy per hour', _rate(MoneyCurrency.cod, eggyPerHour, '/h')),
          _kv('Everything, per hour of play',
              _rate(MoneyCurrency.cod, perHour + eggyPerHour, '/h')),
        ],
      ],
    );
  }

  // -------------------------------------------------------- Per purchase

  Widget _purchaseCard(BuildContext context, BankStats s) {
    // Worked example - a Fruit Platter is +40 cod per purchase, so 250
    // purchases with only that bar owned add 40 * 250 = 10,000 cod.
    final perPurchase = s.owned.codPerPurchase;
    final perPurchaseAll = s.everything.codPerPurchase;
    final purchases = _parseInt(_purchasesCtrl.text) ?? 0;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Dessert Bar, Coffee Bar and Bar',
      children: [
        Text(
          'These three restaurant slots add cod to every purchase a customer '
          'makes. The game does not publish how often customers buy, so this '
          'card asks you for the purchase count rather than guessing it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _kv('Bonus per purchase',
            _amount(MoneyCurrency.cod, perPurchase)),
        if (perPurchaseAll > perPurchase)
          _kv('If you owned them all',
              _amount(MoneyCurrency.cod, perPurchaseAll)),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _purchasesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Purchases',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Count them over any window you like',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        if (purchases > 0) ...[
          const SizedBox(height: 8),
          _kv('Bonus over those purchases',
              _amount(MoneyCurrency.cod, perPurchase * purchases)),
        ],
      ],
    );
  }

  // ------------------------------------------------------ Courtyard gather

  Widget _courtyardGatherCard(BuildContext context, BankStats s) {
    // Worked example - the free Log Door alone pays 95-4,800 cod per gather,
    // so three free gathers a day give 285-14,400 cod, a midpoint of 7,343.
    // The midpoint is the mean of the two ends, not an expected value: the
    // game does not publish the shape of the roll.
    final cod = s.owned.codPerGather;
    final film = s.owned.filmPerGather;
    final codAll = s.everything.codPerGather;
    final filmAll = s.everything.filmPerGather;
    final int gathers = (_parseInt(_gathersCtrl.text) ?? 0).clamp(0, 99).toInt();

    return _card(
      context,
      icon: 'assets/images/film.png',
      title: 'Courtyard gathers',
      children: [
        Text(
          'Courtyard houses, doors, windows, stools and long tables pay cod '
          'when you gather; tables, fences, plants, speakers and decor pay '
          'film. Every one of them is a range, so this card never shows a '
          'single made-up number.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'One gather brings 6–10 customers and each of them gifts you '
          'something. The wiki prints each facility\'s range without saying '
          'whether it is paid once per gather or once per customer, so the '
          'figures below are the per-gather reading — the optimistic case is '
          'up to ten times larger.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (cod.isZero && film.isZero)
          const Text('No courtyard facility that pays out is ticked off yet.')
        else ...[
          if (!cod.isZero) _rangeRows(context, 'Cod per gather', MoneyCurrency.cod, cod),
          if (!film.isZero)
            _rangeRows(context, 'Film per gather', MoneyCurrency.film, film),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: _gathersCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gathers',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '3 free a day, plus up to 6 more from ads',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (gathers > 0) ...[
          const SizedBox(height: 8),
          if (!cod.isZero)
            _kv(
                'Cod over $gathers gather${gathers == 1 ? '' : 's'}',
                _rangeText(MoneyCurrency.cod,
                    cod.scaled(gathers.toDouble()))),
          if (!film.isZero)
            _kv(
                'Film over $gathers gather${gathers == 1 ? '' : 's'}',
                _rangeText(MoneyCurrency.film,
                    film.scaled(gathers.toDouble()))),
        ],
        if (!codAll.isZero || !filmAll.isZero)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Owning every courtyard payout facility would put one gather at '
              '${_fmt(codAll.min)}–${_fmt(codAll.max)} cod and '
              '${_fmt(filmAll.min)}–${_fmt(filmAll.max)} film.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'The midpoint shown is the average of the two ends. The game does '
            'not publish the distribution of the roll, so treat it as a rough '
            'centre, not an expected value.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Concert

  Widget _concertCard(BuildContext context, BankStats s) {
    final double posterPercent =
        (_parseDouble(_posterPercentCtrl.text) ?? 0.0).clamp(0.0, 1000.0).toDouble();
    final bands = s.owned.bandProfitPercent;

    final filmPerformers = s.performers
        .where((p) => p.currency == MoneyCurrency.film)
        .toList()
      ..sort((a, b) {
        final byShow = b.perShow.compareTo(a.perShow);
        return byShow != 0 ? byShow : a.name.compareTo(b.name);
      });
    final codPerformers = s.performers
        .where((p) => p.currency == MoneyCurrency.cod)
        .toList()
      ..sort((a, b) {
        final byShow = b.perShow.compareTo(a.perShow);
        return byShow != 0 ? byShow : a.name.compareTo(b.name);
      });

    // Worked example - Cutie White Bunny earns 10 film/min for a 30 minute
    // show, so perShow is 300 film. With a +50% poster displayed and +13% of
    // Cutie Girlies band bonus from concert decor, the show pays
    // 300 * (1 + (50 + 13) / 100) = 489 film.
    double boosted(PerformerIncome p) {
      final double bandBonus = bands[p.band] ?? 0.0;
      return p.perShow * (1.0 + (posterPercent + bandBonus) / 100.0);
    }

    return _card(
      context,
      icon: 'assets/images/film.png',
      title: 'Concert',
      children: [
        Text(
          'A performer earns their rate every minute of their show, so one '
          'uninterrupted show pays rate × duration. Fan tips during a gather '
          'and the poster bonus are on top.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _posterPercentCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Poster +%',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'The poster bonus only applies when every performer on that '
                'poster is on stage.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),

        if (bands.isNotEmpty) ...[
          const Divider(height: 24),
          Text('Band bonuses from your concert decor',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final band in _sortedKeys(bands))
            _kv(band, _plain('+${_fmt(bands[band] ?? 0)}%')),
        ],

        const Divider(height: 24),
        Text('Film performers, best show first',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        for (final p in filmPerformers)
          _kv(
            '${p.name} · ${p.showDurationMinutes} min',
            _amount(MoneyCurrency.film, boosted(p)),
          ),

        const Divider(height: 24),
        Text('Cod performers, best show first',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        for (final p in codPerformers)
          _kv(
            '${p.name} · ${p.showDurationMinutes} min',
            _amount(MoneyCurrency.cod, boosted(p)),
          ),

        const Divider(height: 24),
        _kv(
            'Ticket Booth cod cap',
            _amount(MoneyCurrency.cod,
                EconomyConstants.ticketBoothCapCod.toDouble())),
        _kv(
            'Ticket Booth film cap',
            _amount(MoneyCurrency.film,
                EconomyConstants.ticketBoothCapFilm.toDouble())),
        _kv('Free daily invites from your lights',
            _plain(_fmt(math.min(
              s.owned.concertDailyInvites,
              EconomyConstants.concertMaxDailyInvitesFromLights.toDouble(),
            )))),
        const SizedBox(height: 8),
        Text(
          'Your lights add up to ${_fmt(s.owned.concertDailyInvites)} invites, '
          'but the game only hands out '
          '${EconomyConstants.concertMaxDailyInvitesFromLights} a day from '
          'lights (plus ${EconomyConstants.concertMaxDailyInvitesFromAds} from '
          'ads and ${EconomyConstants.concertMaxDailyInvitesFromTreasureHunts} '
          'from treasure hunts), so the capped figure is what you can claim.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (s.owned.performerChancePercent > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Your lights also add +${_fmt(s.owned.performerChancePercent)}% '
              'to the chance of inviting a performer.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- Terrace

  Widget _terraceCard(
      BuildContext context, BankStats s, List<TerraceCustomer> customers) {
    final perGather = _parseInt(_terraceCodCtrl.text) ?? 0;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Terrace',
      children: [
        _kv('"Customers pay" bonus, summed',
            _amount(MoneyCurrency.cod, s.owned.terracePayFlatCod)),
        _kv('"Customers pay more" bonus, summed',
            _plain('+${_fmt(s.owned.terracePayPercent)}%')),
        _kv('Cod per flower view, summed',
            _amount(MoneyCurrency.cod, s.owned.codPerFlowerView)),
        _kv('Free bottles per day', _plain(_fmt(s.owned.bottlesPerDay))),
        _kv('Free table refreshes per day',
            _plain(_fmt(s.owned.tableRefreshes))),
        _kv('Gathers per day',
            _plain('${EconomyConstants.terraceGathersPerDay}')),

        const SizedBox(height: 8),
        Text(
          'The first three lines add up every terrace table, stand, cinema and '
          'telescope you own, following the game\'s rule that unlocked '
          'facilities combine. What the wiki does not say is whether "customers '
          'pay +X" is charged once per customer or once per gather, or whether '
          'the percentages add or multiply — so read these as the size of your '
          'terrace investment rather than as cod you are about to receive.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Gather cooldowns run '
          '${EconomyConstants.terraceGatherCooldownMinutes.join(', ')} minutes, '
          'so all six take about '
          '${_hoursText(EconomyConstants.terraceGatherCooldownMinutes.fold<int>(0, (a, b) => a + b) / 60)} '
          'of elapsed time. A rejected gather costs 1–50 minutes instead.',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const Divider(height: 24),
        Text(
          'How much a whole gather pays depends on how many customers turn up '
          'and what they order, and the game publishes neither. Enter what one '
          'gather actually gave you and this projects a day.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _terraceCodCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cod per gather',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('From your own game',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (perGather > 0)
          ...[
            for (int n = 1; n <= EconomyConstants.terraceGathersPerDay; n++)
              _kv(
                '$n gather${n == 1 ? '' : 's'}'
                '${n == EconomyConstants.terraceGathersPerDay ? ' (daily max)' : ''}',
                _amount(MoneyCurrency.cod, (perGather * n).toDouble()),
              ),
          ]
        else
          Text('Enter a cod-per-gather value above to see daily totals.',
              style: Theme.of(context).textTheme.bodySmall),

        const Divider(height: 24),

        Text('Terrace customers',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'Unlocked by promoting the terrace. Promo count is the number of '
          'promotions that guarantees them (pity system).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),

        for (final c in customers) _terraceCustomerTile(context, c),
      ],
    );
  }

  Widget _terraceCustomerTile(BuildContext context, TerraceCustomer c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (c.promoLevel != null) _pill(context, c.promoLevel!),
              const SizedBox(width: 6),
              _pill(context, '${c.promoCount} promo'),
            ],
          ),
          if (c.requiredFoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Needs: ${c.requiredFoods.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer)),
    );
  }

  // ---------------------------------------------------------------- Takeout

  Widget _takeoutCard(BuildContext context, BankStats s) {
    final orders = s.owned.takeoutOrders;
    final ordersAll = s.everything.takeoutOrders;

    return _card(
      context,
      icon: 'assets/images/bell.png',
      title: 'Takeout',
      children: [
        _kv('Extra orders from Provision Tables', _plain(_fmt(orders))),
        if (ordersAll > orders)
          _kv('If you owned them all', _plain(_fmt(ordersAll))),
        _kv('Goods capacity added', _plain(_fmt(s.owned.takeoutCapacity))),
        _kv('Documented daily ceiling',
            _plain('${EconomyConstants.takeoutMaxOrdersPerDay} orders')),
        const SizedBox(height: 8),
        Text(
          'Bells come from completing orders, and what one order pays depends '
          'on the item, its quantity and its quality — none of which the game '
          'publishes as a formula. So this card counts order slots, not bells. '
          'Support Chef Meow\'s raise adds more daily orders on top of the '
          'Provision Tables.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ----------------------------------------------------------- Fishing pond

  Widget _fishingCard(BuildContext context, BankStats s) {
    // Worked example - Traditional Popcorn pays "10 plates or 100 cod" once
    // every 5 minutes, so one booth left for an hour makes 60 / 5 = 12
    // payouts: at worst 12 * 10 = 120 plates, at best 12 * 100 = 1,200 cod,
    // and in reality some mix of the two that nobody has published the odds
    // for. Both ends are shown; no average is invented between them.
    final int booths = (_parseInt(_boothsCtrl.text) ?? 0).clamp(0, 20).toInt();
    final int minutes =
        (_parseInt(_boothMinutesCtrl.text) ?? 0).clamp(0, 100000).toInt();
    final payouts = minutes ~/ EconomyConstants.boothPayoutIntervalMinutes;

    // Best and worst a single booth can pay per 5 minutes, across every booth
    // owner in the data.
    var bestCod = 0.0;
    var bestPlates = 0.0;
    var worstCod = double.infinity;
    var worstPlates = double.infinity;
    var withKnownChances = 0;
    for (final b in s.booths) {
      for (final amount in b.amountsOf(MoneyCurrency.cod)) {
        bestCod = math.max(bestCod, amount);
        worstCod = math.min(worstCod, amount);
      }
      for (final amount in b.amountsOf(MoneyCurrency.plates)) {
        bestPlates = math.max(bestPlates, amount);
        worstPlates = math.min(worstPlates, amount);
      }
      if (b.chancesKnown) withKnownChances++;
    }
    if (!worstCod.isFinite) worstCod = 0.0;
    if (!worstPlates.isFinite) worstPlates = 0.0;

    return _card(
      context,
      icon: 'assets/images/plate.png',
      title: 'Fishing pond booths',
      children: [
        Text(
          'A leased booth pays once every 5 minutes, and each payout is '
          'either plates or the booth\'s other reward — never both. The game '
          'does not publish how the two split, so there is no honest single '
          'number here, only the range.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _kv('Booth owners with payout data', _plain(_fmt(s.booths.length))),
        _kv('…of those, with published odds', _plain(_fmt(withKnownChances))),
        _kv('Plates per payout, across all booths',
            _rangeText(MoneyCurrency.plates,
                AmountRange(worstPlates, bestPlates))),
        _kv('Cod per payout, across all booths',
            _rangeText(MoneyCurrency.cod, AmountRange(worstCod, bestCod))),

        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: _boothsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Booths',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _boothMinutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$payouts payout${payouts == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        if (booths > 0 && payouts > 0) ...[
          const SizedBox(height: 8),
          _kv(
              'Plates, if every payout were plates',
              _rangeText(
                  MoneyCurrency.plates,
                  AmountRange(worstPlates, bestPlates)
                      .scaled((booths * payouts).toDouble()))),
          _kv(
              'Cod, if every payout were cod',
              _rangeText(
                  MoneyCurrency.cod,
                  AmountRange(worstCod, bestCod)
                      .scaled((booths * payouts).toDouble()))),
          const SizedBox(height: 4),
          Text(
            'Those two lines are the two extremes of the same payouts, not two '
            'incomes you get at once. A booth also leaves after its own stay '
            'timer, which is per-owner.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Booth owners drawn in by a rare fish have a '
            '${(EconomyConstants.rareFishDiamondChance * 100).round()}% chance '
            'of ${EconomyConstants.rareFishDiamondAmount} diamonds. Rare fish '
            'spawn every 12 to 72 hours.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------- Gachapon / wishes

  Widget _drawsCard(BuildContext context, BankStats s) {
    return _card(
      context,
      icon: 'assets/images/star.png',
      title: 'Gachapon and Wishing Well',
      children: [
        _kv('Your Gachapon draws per day', _plain(_fmt(s.owned.gachaDraws))),
        _kv('Highest Gachapon level', _plain('${s.owned.gachaMaxLevel}')),
        _kv('Your wishes per day', _plain(_fmt(s.owned.wishingWellWishes))),
        _kv('Highest Wishing Well level',
            _plain('${s.owned.wishingWellMaxLevel}')),
        _kv('Garden Table flower views added',
            _plain(_fmt(s.owned.flowerViews))),
        const SizedBox(height: 8),
        Text(
          'Usage caps for the Gachapon and the Wishing Well combine across '
          'every unlocked machine, which is why these add up. Owning every '
          'machine sums to ${_fmt(s.everything.gachaDraws)} draws, while the '
          'wiki\'s own summary says '
          '${EconomyConstants.gachaponMaxDrawsPerDay} plus one free draw a '
          'side; one of those two figures is stale and we could not tell '
          'which, so both are shown.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'What a draw is worth is not modelled: the Gachapon uses a weighted '
          'prize pool the game does not publish.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Sources

  Widget _sourcesCard(BuildContext context, BankStats s) {
    return _card(
      context,
      icon: 'assets/images/star.png',
      title: 'Where these numbers come from',
      children: [
        Text(
          'Facility income is transcribed from the Animal Restaurant wiki '
          'facility tables with the printed units kept intact — per minute, '
          'per hour, per day, per gather and per 30 seconds are all different '
          'things and are never mixed here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (s.dataRetrieved != null)
          _kv('Income table read on', _plain(s.dataRetrieved!)),
        _kv('Facilities in the data', _plain(_fmt(s.totalFacilityCount))),
        _kv('…with a verified income effect',
            _plain(_fmt(s.facilitiesWithIncome))),
        const SizedBox(height: 8),
        Text(
          'Not modelled anywhere on this page: what a customer pays for a '
          'dish, promotion, letters, achievements, events, the battle pass, '
          'redemption codes, Gachapon prizes, and the vegetable garden\'s '
          'buttons. None of them have a published formula.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ Helpers

  Widget _card(
    BuildContext context, {
    required String icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  icon,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  /// A "min / mid / max" trio for a randomised payout.
  Widget _rangeRows(
    BuildContext context,
    String label,
    MoneyCurrency currency,
    AmountRange r,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('$label — lowest', _amount(currency, r.min)),
        _kv('$label — midpoint', _amount(currency, r.mid)),
        _kv('$label — highest', _amount(currency, r.max)),
      ],
    );
  }

  int? _parseInt(String t) {
    final s = t.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  double? _parseDouble(String t) {
    final s = t.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  List<String> _sortedKeys(Map<String, double> m) {
    final keys = m.keys.toList();
    keys.sort();
    return keys;
  }

  String _minutesLabel(double minutes) {
    if (minutes <= 0) return 'Enter minutes';
    if (minutes < 60) return '${_fmt(minutes)} min';
    return _hoursText(minutes / 60.0);
  }

  String _hoursText(double h) {
    if (!h.isFinite) return '—';
    if (h == h.roundToDouble()) return '${h.toInt()} h';
    return '${h.toStringAsFixed(1)} h';
  }

  Widget _kv(String k, Widget vWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k)),
          const SizedBox(width: 8),
          DefaultTextStyle(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: Align(alignment: Alignment.centerRight, child: vWidget),
          ),
        ],
      ),
    );
  }

  Widget _plain(String text) => Text(text);

  Widget _currencyIcon(MoneyCurrency c) => Image.asset(
        c.assetPath,
        width: 20,
        height: 20,
        errorBuilder: (_, __, ___) => const SizedBox(width: 20),
      );

  Widget _amount(MoneyCurrency c, double v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _currencyIcon(c),
        const SizedBox(width: 4),
        Text(_fmt(v)),
      ],
    );
  }

  Widget _rate(MoneyCurrency c, double v, String suffix) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _currencyIcon(c),
        const SizedBox(width: 4),
        Text('${_fmt(v)}$suffix'),
      ],
    );
  }

  Widget _rangeText(MoneyCurrency c, AmountRange r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _currencyIcon(c),
        const SizedBox(width: 4),
        Text(r.isExact ? _fmt(r.min) : '${_fmt(r.min)}–${_fmt(r.max)}'),
      ],
    );
  }

  /// Thousands-separated, rounded to a whole unit.
  String _fmt(num value) {
    if (value is double && !value.isFinite) return '—';
    final rounded = value.round();
    final neg = rounded < 0;
    final s = rounded.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return neg ? '-$buf' : buf.toString();
  }
}
