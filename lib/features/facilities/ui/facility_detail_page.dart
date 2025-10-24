import 'package:animal_restaurant_tracker/features/economy/model/currency.dart';
import 'package:flutter/material.dart';
import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/money_bag.dart';
import '../../shared/data/unlocked_store.dart';
import '../model/facility.dart';

class FacilityDetailPage extends StatefulWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  int hours = 12; // adjustable window
  final store = UnlockedStore.instance;

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final purchased = store.isUnlocked('facility_purchased', f.id);

    MoneyBag minBag = EarningsCalculator.minimumOverHours(
      facilities: [f],
      isPurchased: (_) => purchased,
      hours: hours,
    );

    return Scaffold(
      appBar: AppBar(title: Text(f.name)),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final isBought = store.isUnlocked('facility_purchased', f.id);
          minBag = EarningsCalculator.minimumOverHours(
            facilities: [f],
            isPurchased: (_) => isBought,
            hours: hours,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Purchased'),
                value: isBought,
                onChanged: (v) => store.setUnlocked('facility_purchased', f.id, v),
              ),
              const SizedBox(height: 8),
              const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              ...f.prices.map((p) => Text('${p.amount} ${p.currency.key}')),
              const SizedBox(height: 12),
              const Text('Yields', style: TextStyle(fontWeight: FontWeight.bold)),
              ...f.yields.map((y) => Text(
                  '${y.type} • ${y.amount}${y.maxAmount != null ? '-${y.maxAmount}' : ''} ${y.currency.key}'
                  '${y.intervalMinutes != null ? ' / ${y.intervalMinutes}m' : ''}'
                  '${y.goesToTips ? ' (tips)' : ''}'
              )),
              const Divider(height: 24),
              Row(
                children: [
                  const Text('Window: '),
                  DropdownButton<int>(
                    value: hours,
                    items: const [1,3,6,12].map((h) => DropdownMenuItem(value: h, child: Text('${h}h'))).toList(),
                    onChanged: (v) => setState(() => hours = v ?? 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Minimum in $hours h: ${minBag.toString()}'),
              const SizedBox(height: 24),
              const Text('Note: "Minimum" uses the lower bound for any ranges and ignores one-time purchase bonuses unless you explicitly include them.'),
            ],
          );
        },
      ),
    );
  }
}