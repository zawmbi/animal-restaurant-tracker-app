import 'package:flutter/material.dart';
import '../data/bank_service.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final _service = BankService();

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
                      const Text('Failed to load bank stats',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
              _totalCard(context, s),
              const SizedBox(height: 12),
              _buffetCard(context, s),
              const SizedBox(height: 12),
              _tipJarCard(context, s),
              const SizedBox(height: 12),
              _terraceCard(context, s),
              const SizedBox(height: 12),
              _courtyardCard(context, s),
              const SizedBox(height: 24),
              _hint(context),
            ],
          );
        },
      ),
    );
  }

  Widget _totalCard(BuildContext context, BankStats s) {
    final low = s.totalLow;
    final high = s.totalHigh;
    final same = low == high;

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
                Text('Total per hour',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              same ? _cod(low) : '${_cod(low)} — ${_cod(high)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buffetCard(BuildContext context, BankStats s) {
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
                Text('Buffet',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _kv('Current (checked recipes)', _cod(s.buffetPerHourCurrent)),
            _kv('Potential (all buffet)', _cod(s.buffetPerHourAll)),
            if (s.buffetPerHourAll > s.buffetPerHourCurrent)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${_cod(s.buffetPerHourAll - s.buffetPerHourCurrent)} '
                  'available by unlocking more buffet recipes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tipJarCard(BuildContext context, BankStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_atm),
                const SizedBox(width: 8),
                Text('Tip Jar',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _kv(
              'Earnings per hour',
              s.tipJarPerHour != null
                  ? _cod(s.tipJarPerHour!)
                  : '— (not owned or unknown)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _terraceCard(BuildContext context, BankStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.park),
                const SizedBox(width: 8),
                Text('Terrace',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _kv(
              'Range per hour',
              s.terraceRange != null
                  ? '${_cod(s.terraceRange!.min)} — ${_cod(s.terraceRange!.max)}'
                  : '— (facility not owned or unknown)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _courtyardCard(BuildContext context, BankStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.yard),
                const SizedBox(width: 8),
                Text('Courtyard',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _kv(
              'Range per hour',
              s.courtyardRange != null
                  ? '${_cod(s.courtyardRange!.min)} — ${_cod(s.courtyardRange!.max)}'
                  : '— (facility not owned or unknown)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _cod(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return '$buf cod/h';
  }

  Widget _hint(BuildContext context) {
    return Text(
      'Note: Terrace/Courtyard ranges currently use base values from BankConfig. '
      'Tie them to facilities and customer/performer counts when those fields are available.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
