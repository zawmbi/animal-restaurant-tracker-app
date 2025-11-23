import 'package:flutter/material.dart';
import '../data/bank_service.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final _service = BankService();
  final _hoursCtrl = TextEditingController(text: '3'); // default 3h example

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank')),
      body: FutureBuilder<BankStats>(
        future: _service.compute(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failed to load bank stats',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text('${snap.error}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final s = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _totalFacilitiesCard(context, s),
              const SizedBox(height: 12),
              _buffetCard(context, s),
              const SizedBox(height: 12),
              _platesCard(context, s),
            ],
          );
        },
      ),
    );
  }

  // ---------- All facilities cod per hour ----------

  Widget _totalFacilitiesCard(BuildContext context, BankStats s) {
    final current = s.totalCodPerHourCurrent;
    final all = s.totalCodPerHourAll;
    final diff = all - current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings),
                const SizedBox(width: 8),
                Text(
                  'All facilities (cod per hour)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _codPerHour(current),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (diff > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+${_formatNumber(diff)} cod/h available by '
                'checking more cod-making facilities',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Buffet card: 1h, 12h, custom hours + ad bonus ----------

  Widget _buffetCard(BuildContext context, BankStats s) {
    final perHour = s.buffetPerHourCurrent;
    final perHourAll = s.buffetPerHourAll;

    final base1h = perHour;
    final base12h = perHour * 12;

    final base1hWithAd = _withAdBonus(base1h);
    final base12hWithAd = _withAdBonus(base12h);

    final rawHours = _parseHours() ?? 3.0;
    final clampedHours = rawHours.clamp(1.0, 12.0);
    final baseCustom = (perHour * clampedHours).round();
    final customWithAd = _withAdBonus(baseCustom);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_bar),
                const SizedBox(width: 8),
                Text(
                  'Buffet (stacks up to 12 hours)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (perHour == 0)
              const Text(
                'No buffet cod facilities are checked yet.',
              )
            else ...[
              _kv('Buffet cod per hour', _codAmount(base1h)),

              const SizedBox(height: 8),
              Text(
                'Preset collections',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _kv('1 hour', _codAmount(base1h)),
              _kv('1 hour + ad (max +1,500,000)',
                  _codAmount(base1hWithAd)),
              const SizedBox(height: 4),
              _kv('12 hours (max stack)', _codAmount(base12h)),
              _kv('12 hours + ad (max +1,500,000)',
                  _codAmount(base12hWithAd)),

              const SizedBox(height: 12),
              Text(
                'Custom hours (1–12)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _hoursCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using ${clampedHours.toStringAsFixed(2)} h '
                      '(clamped between 1 and 12).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _kv('Custom', _codAmount(baseCustom)),
              _kv('Custom + ad (max +1,500,000)',
                  _codAmount(customWithAd)),
            ],

            if (perHourAll > perHour) ...[
              const SizedBox(height: 12),
              Text(
                '+${_codAmount(perHourAll - perHour)} per hour '
                'available by checking more buffet facilities',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Plates card ----------

  Widget _platesCard(BuildContext context, BankStats s) {
    final current = s.platesPerDayCurrent;
    final all = s.platesPerDayAll;
    final diff = all - current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_food_beverage),
                const SizedBox(width: 8),
                Text(
                  'Daily Plates from facilities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _platesPerDay(current),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (diff > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+${_formatNumber(diff)} plates/day available by '
                'checking more plate-making facilities',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  double? _parseHours() {
    final txt = _hoursCtrl.text.trim();
    if (txt.isEmpty) return null;
    return double.tryParse(txt);
  }

  /// 1.5x bonus, but the **extra** cod (the 0.5x part) is capped at 1,500,000.
  /// So final = base + min(base * 0.5, 1,500,000).
  int _withAdBonus(int base) {
    if (base <= 0) return base;
    const cap = 1500000;
    final bonus = (base * 0.5).round();
    final cappedBonus = bonus > cap ? cap : bonus;
    return base + cappedBonus;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _codPerHour(int v) => '${_formatNumber(v)} cod/h';

  String _codAmount(int v) => '${_formatNumber(v)} cod';

  String _platesPerDay(int v) => '${_formatNumber(v)} plates/day';
}
