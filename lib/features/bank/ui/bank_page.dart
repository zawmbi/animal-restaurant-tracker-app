import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  // Buffet: hours left to accumulate (1–12).
  final _buffetHoursCtrl = TextEditingController(text: '3');

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
    _buffetHoursCtrl.dispose();
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
              _tipJarCard(context, s),
              const SizedBox(height: 12),
              _buffetCard(context, s),
              const SizedBox(height: 12),
              _terraceCard(context, data.terrace),
              const SizedBox(height: 12),
              if (s.onlineCodPerHourCurrent > 0 || s.onlineCodPerHourAll > 0) ...[
                _onlineCodCard(context, s),
                const SizedBox(height: 12),
              ],
              _platesCard(context, s),
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

  // ---------------------------------------------------------------- Tip Jar

  Widget _tipJarCard(BuildContext context, BankStats s) {
    final cap = s.tipCapCurrent;
    final capAll = s.tipCapAll;
    final fillPerHour = s.tipFillPerHourCurrent;
    final fillPerHourAll = s.tipFillPerHourAll;

    // Tips accrue for at most 12 hours offline, and never past the jar's cap.
    int collectableAt(int minutes) {
      if (fillPerHour <= 0) return 0;
      final cappedMinutes = math.min(minutes, 12 * 60);
      final accrued = (fillPerHour / 60.0) * cappedMinutes;
      final hardCap = cap > 0 ? cap.toDouble() : double.infinity;
      return math.min(accrued, hardCap).round();
    }

    final minutes = _parseInt(_tipMinutesCtrl.text) ?? 0;
    final answer = collectableAt(minutes);
    final answerWithAd = answer * 2;

    // Minutes needed to fully fill the jar (if reachable within 12h).
    final minutesToFill =
        (fillPerHour > 0 && cap > 0) ? (cap / (fillPerHour / 60.0)) : 0.0;
    final fillsWithin12h = minutesToFill > 0 && minutesToFill <= 12 * 60;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Tip Jar',
      children: [
        _kv('Jar capacity', _cod(cap)),
        _kv('Fill rate (checked)', _codPerHour(fillPerHour)),
        if (fillPerHourAll > fillPerHour)
          _kv('Fill rate (all possible)', _codPerHour(fillPerHourAll)),

        const Divider(height: 24),

        Text('How much will the jar hold after…',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Quick reference rows.
        _kv('1 minute', _cod(collectableAt(1))),
        _kv('1 hour', _cod(collectableAt(60))),
        _kv('6 hours', _cod(collectableAt(360))),
        _kv('12 hours (max)', _cod(collectableAt(720))),

        const SizedBox(height: 12),

        // Custom duration input.
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
        _kv('Collectable', _cod(answer)),
        _kv('With ad (2×)', _cod(answerWithAd)),

        if (fillPerHour > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              fillsWithin12h
                  ? 'Jar fills completely in ${_hoursText(minutesToFill / 60.0)}.'
                  : 'At this rate the jar never fully fills within the 12h offline window — '
                      'it tops out at ${_formatNumber(collectableAt(720))} cod.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        if (capAll > cap)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${_formatNumber(capAll - cap)} capacity available by checking more tip desk facilities.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------- Buffet

  Widget _buffetCard(BuildContext context, BankStats s) {
    final perHour = s.buffetPerHourCurrent;
    final perHourAll = s.buffetPerHourAll;

    final rawHours = _parseDouble(_buffetHoursCtrl.text) ?? 3.0;
    final hours = rawHours.clamp(0.0, 12.0);
    final base = (perHour * hours).round();

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Buffet Income (maxes at 12 hours)',
      children: [
        if (perHour == 0)
          const Text('No buffet cod facilities are checked yet.')
        else ...[
          _kv('Buffet cod per hour', _codPerHour(perHour)),

          const Divider(height: 24),

          Text('How much after…',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _kv('1 hour', _cod(perHour)),
          _kv('6 hours', _cod(perHour * 6)),
          _kv('12 hours (max)', _cod(perHour * 12)),

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
                    labelText: 'Hours (0–12)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${hours.toStringAsFixed(1)} h',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Without ad', _cod(base)),
          _kv('With ad (1.5×, max +1,500,000)', _cod(_withBuffetAdBonus(base))),
        ],

        if (perHourAll > perHour)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '+${_formatNumber(perHourAll - perHour)} cod/h available by checking more buffet facilities.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- Terrace

  Widget _terraceCard(BuildContext context, List<TerraceCustomer> customers) {
    final perGather = _parseInt(_terraceCodCtrl.text) ?? 0;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Terrace',
      children: [
        Text(
          'The terrace hosts up to 6 gathers per day. Each gather gifts bottles, '
          'cod and bells — the cod amount varies with your rating, facilities and '
          'who attends, so enter what you see for one gather to project a day.',
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
            for (int n = 1; n <= 6; n++)
              _kv(
                '$n gather${n == 1 ? '' : 's'}${n == 6 ? ' (daily max)' : ''}',
                _cod(perGather * n),
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

  // ------------------------------------------------------------------ Online

  Widget _onlineCodCard(BuildContext context, BankStats s) {
    final current = s.onlineCodPerHourCurrent;
    final all = s.onlineCodPerHourAll;
    final diff = all - current;

    return _card(
      context,
      icon: 'assets/images/cod.png',
      title: 'Online-only cod (non-tip, non-buffet)',
      children: [
        _kv('Cod per hour (checked)', _codPerHour(current)),
        _kv('Cod per hour (all possible)', _codPerHour(all)),
        if (diff > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${_formatNumber(diff)} cod/h available by checking more online-only facilities.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ Plates

  Widget _platesCard(BuildContext context, BankStats s) {
    final current = s.platesPerDayCurrent;
    final all = s.platesPerDayAll;
    final diff = all - current;

    return _card(
      context,
      icon: 'assets/images/plate.png',
      title: 'Daily Plates from facilities',
      children: [
        Row(
          children: [
            Image.asset('assets/images/plate.png', width: 26, height: 26),
            const SizedBox(width: 6),
            Text(_formatNumber(current),
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        if (diff > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${_formatNumber(diff)} plates/day available by checking more plate-making facilities.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
                Image.asset(icon, width: 22, height: 22),
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

  int _withBuffetAdBonus(int base) {
    if (base <= 0) return base;
    const cap = 1500000;
    final bonus = (base * 0.5).round();
    return base + (bonus > cap ? cap : bonus);
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

  String _minutesLabel(int minutes) {
    if (minutes <= 0) return 'Enter minutes';
    if (minutes < 60) return '$minutes min';
    final h = minutes / 60.0;
    final capped = minutes > 720 ? ' (capped at 12h)' : '';
    return '${_hoursText(h)}$capped';
  }

  String _hoursText(double h) {
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

  Widget _codPerHour(int v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/cod.png', width: 20, height: 20),
        const SizedBox(width: 4),
        Text('${_formatNumber(v)}/h'),
      ],
    );
  }

  Widget _cod(int v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/cod.png', width: 20, height: 20),
        const SizedBox(width: 4),
        Text(_formatNumber(v)),
      ],
    );
  }

  String _formatNumber(int v) {
    final neg = v < 0;
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return neg ? '-$buf' : buf.toString();
  }
}
