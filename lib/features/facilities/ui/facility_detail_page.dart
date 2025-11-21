import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../../economy/logic/earnings_calculator.dart';
import '../../economy/model/money_bag.dart';
import '../model/facility.dart';

class FacilityDetailPage extends StatelessWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;

    return Scaffold(
      appBar: AppBar(title: Text(facility.name)),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final purchased = store.isUnlocked('facility_purchased', facility.id);

          // Calculate 12h minimum for THIS facility (preview alone).
          MoneyBag? total12h;
          String totalText = '';
          String perHourText = '';
          try {
            total12h = EarningsCalculator.minimumOverHours(
              facilities: [facility],
              isPurchased: (_) => true,
              hours: 12,
            );
            totalText = _formatBag(total12h);
            perHourText = _formatBagDivided(total12h, 12);
          } catch (_) {
            total12h = null;
            totalText = '—';
            perHourText = '—';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionCard(
                context,
                title: 'Ownership',
                child: Row(
                  children: [
                    Checkbox(
                      value: purchased,
                      onChanged: (v) => store.setUnlocked(
                        'facility_purchased',
                        facility.id,
                        v ?? false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(purchased ? 'Purchased' : 'Not purchased'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                context,
                title: 'Overview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('Area', _areaLabel(facility.area)),
                    _kv('Group', facility.group),
                    if (facility.requirementStars != null)
                      _kv('Stars Required', '${facility.requirementStars}'),
                    if (facility.series != null) _kv('Series', facility.series!),
                    if (facility.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(facility.description!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                context,
                title: 'Price',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: facility.price
                      .map((p) => Chip(
                            label: Text('${_fmtInt(p.amount)} ${p.currency.name}'),
                            side: const BorderSide(width: 1),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                context,
                title: 'Effects',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final eff in facility.effects) _effectTile(context, eff),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Event-based income (e.g., performances) is not included in the 12-hour minimum unless an event rate is provided.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                context,
                title: 'Earnings (This Facility)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('12-hour total', totalText),
                    _kv('Avg per hour', perHourText),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- helpers ----

  Widget _sectionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
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
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  String _areaLabel(FacilityArea a) {
    switch (a) {
      case FacilityArea.restaurant:
        return 'Restaurant';
      case FacilityArea.kitchen:
        return 'Kitchen';
      case FacilityArea.garden:
        return 'Garden';
      case FacilityArea.buffet:
        return 'Buffet';
      case FacilityArea.takeout:
        return 'Takeout';
      case FacilityArea.terrace:
        return 'Terrace';
      case FacilityArea.courtyard:
        return 'Courtyard';
      case FacilityArea.courtyard_concert:
        return 'Courtyard (Concert)';
      case FacilityArea.courtyard_pets:
        return 'Courtyard (Pets)';
    }
  }

  Widget _effectTile(BuildContext context, FacilityEffect eff) {
    String text;
    switch (eff.type) {
      case FacilityEffectType.incomePerMinute:
        final amt = eff.amount ?? 0;
        final cur = eff.currency?.name ?? 'cod';
        text = '+${_fmtNum(amt)} $cur / min';
        break;
      case FacilityEffectType.incomePerInterval:
        final amt = eff.amount ?? 0;
        final cur = eff.currency?.name ?? 'cod';
        final every = eff.intervalMinutes ?? 0;
        text = '+${_fmtNum(amt)} $cur every ${every}m';
        break;
      case FacilityEffectType.incomePerEventRange:
        final min = eff.min ?? 0;
        final max = eff.max;
        final cur = eff.currency?.name ?? 'cod';
        final label = eff.eventKey ?? 'event';
        text = max == null ? '$min $cur per $label (min)' : '$min–$max $cur per $label';
        break;
      case FacilityEffectType.tipCapIncrease:
        final cap = eff.capIncrease ?? 0;
        text = 'Tip cap +${_fmtInt(cap)}';
        break;
      case FacilityEffectType.ratingBonus:
        final r = eff.amount ?? 0;
        text = '+${_fmtNum(r)} rating';
        break;
      case FacilityEffectType.gachaDraws:
        // uses amount as number of draws
        final draws = eff.amount?.toInt() ?? 0;
        text = '+$draws draws';
        break;
      case FacilityEffectType.gachaLevel:
        // If your model doesn’t parse a dedicated "level" field, store it in amount.
        final lvl = eff.amount?.toInt();
        text = 'Gachapon Level ${lvl ?? '-'}';
        break;

      case FacilityEffectType.cookingEfficiencyBonus:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _fmtInt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _fmtNum(num v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  String _formatBag(MoneyBag bag) {
    String fmt(double v) =>
        v.abs() < 0.0001 ? '0' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));
    return [
      'Cod: ${fmt(bag.get(MoneyCurrency.cod))}',
      'Plates: ${fmt(bag.get(MoneyCurrency.plates))}',
      'Bells: ${fmt(bag.get(MoneyCurrency.bells))}',
      'Film: ${fmt(bag.get(MoneyCurrency.film))}',
      'Buttons: ${fmt(bag.get(MoneyCurrency.buttons))}',
    ].join('  •  ');
  }

  String _formatBagDivided(MoneyBag bag, int divisor) {
  String fmt(double v) =>
      v.abs() < 0.0001 ? '0' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));
  return [
    'Cod: ${fmt(bag.get(MoneyCurrency.cod) / divisor)}',
    'Plates: ${fmt(bag.get(MoneyCurrency.plates) / divisor)}',
    'Bells: ${fmt(bag.get(MoneyCurrency.bells) / divisor)}',
    'Film: ${fmt(bag.get(MoneyCurrency.film) / divisor)}',
    'Buttons: ${fmt(bag.get(MoneyCurrency.buttons) / divisor)}',
  ].join('  •  ');
}

}
