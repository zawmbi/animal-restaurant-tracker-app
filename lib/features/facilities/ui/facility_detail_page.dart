import 'package:flutter/material.dart';

import '../../completion/data/progress_types.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/facilities_repository.dart';
import '../model/facility.dart';

// This file holds FacilityDetailPage only.
//
// It used to open with a second, unreachable copy of FacilitiesPage and its
// _ScenesBar, _ThemeRail and _FacilityGroupSection — 320 lines that nothing
// imported. Both real callers, home_page.dart and progress_page.dart, resolve
// FacilitiesPage from facilities_page.dart. The dead copy was a trap: it
// carried its own drifted versions of the same layout bugs, so anyone fixing
// the facilities grid had even odds of editing the file nobody runs.

/// ========= Facility Detail Page (styled like DishDetailPage) =========

class FacilityDetailPage extends StatelessWidget {
  const FacilityDetailPage({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context) {
    final repo = FacilitiesRepository.instance;
    final store = UnlockedStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Facility Details')),
      body: FutureBuilder<Facility?>(
        future: repo.byId(facilityId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load facility:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final facility = snap.data;
          if (facility == null) {
            return const Center(child: Text('Facility not found.'));
          }

          // Rebuild when unlock state changes so the checkbox updates.
          return AnimatedBuilder(
            animation: store,
            builder: (context, _) =>
                _FacilityDetailBody(facility: facility, store: store),
          );
        },
      ),
    );
  }
}

class _FacilityDetailBody extends StatelessWidget {
  const _FacilityDetailBody({
    required this.facility,
    required this.store,
  });

  final Facility facility;
  final UnlockedStore store;

  //Use your PNGs: assets/images/<currencyKey>.png
  static String _currencyAsset(MoneyCurrency c) => 'assets/images/${c.key}.png';

  String _prettyArea(FacilityArea area) => area.name
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    // This page is reached from search, customer requirements, battle pass
    // rewards and redemption codes, so it can be showing any area — including
    // the courtyard, whose facilities are tracked in a different bucket. It
    // used to write 'facility' for all of them, which meant ticking a
    // courtyard item here was invisible to the Courtyard page and to the
    // completion percentage.
    final bucket = ProgressTypes.facilityBucketFor(facility.area.name);
    final checked = store.isUnlocked(bucket, facility.id);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------- Title Row (like recipe) ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                facility.name,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (v) =>
                  store.setUnlocked(bucket, facility.id, v ?? false),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---------- Description ----------
        if (facility.description != null &&
            facility.description!.trim().isNotEmpty)
          Text(
            facility.description!,
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),

        // ---------- Main info card ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(context, 'Group', facility.group),
                _infoRow(context, 'Area', _prettyArea(facility.area)),
                if (facility.series != null &&
                    facility.series!.trim().isNotEmpty)
                  _infoRow(context, 'Series', facility.series!),
                _infoRow(
                  context,
                  'Star requirement',
                  (facility.requiredStars != null &&
                          facility.requiredStars! > 0)
                      ? '${facility.requiredStars}★'
                      : '—',
                ),

                //  Price row using your currency PNGs
                _infoRowWidget(
                  context,
                  'Price',
                  _pricePills(context, facility.price),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ---------- Effects section ----------
        if (facility.effects.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effects',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...facility.effects
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${_formatEffect(e)}'),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ---------- Special requirements (events, etc.) ----------
        if ((facility.specialRequirements ?? const []).isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special requirements',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...facility.specialRequirements!
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $s'),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Helper UI ----------

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWidget(BuildContext context, String label, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricePills(BuildContext context, List<Price> prices) {
    if (prices.isEmpty) {
      return const Text(
        'Free',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: prices.map((p) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _currencyAsset(p.currency),
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.attach_money, size: 18),
            ),
            const SizedBox(width: 6),
            Text(
              '${_formatNumber(p.amount)} ${p.currency.key}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        );
      }).toList(),
    );
  }

  static String _formatNumber(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _formatEffect(FacilityEffect e) {
    String amountStr = '';
    if (e.amount != null) {
      final a = e.amount!;
      amountStr = a % 1 == 0 ? a.toInt().toString() : a.toStringAsFixed(2);
    }

    switch (e.type) {
      case FacilityEffectType.ratingBonus:
        return '+$amountStr rating';
      case FacilityEffectType.incomePerMinute:
        final cur = e.currency?.key ?? '';
        return '+$amountStr $cur / min';
      case FacilityEffectType.tipCapIncrease:
        final cap = e.capIncrease ?? (e.amount?.toInt() ?? 0);
        return 'Tip cap +$cap';
      case FacilityEffectType.incomePerInterval:
        final cur = e.currency?.key ?? '';
        final mins = e.intervalMinutes ?? 0;
        return '+$amountStr $cur every $mins min';
      case FacilityEffectType.incomePerEventRange:
        final min = e.min ?? 0;
        final max = e.max;
        final cur = e.currency?.key ?? '';
        final range = max == null ? '$min' : '$min–$max';
        final key = e.eventKey ?? 'event';
        return '$range $cur per $key';
      case FacilityEffectType.gachaDraws:
        return '${e.amount?.toInt() ?? 0} gacha draws';
      case FacilityEffectType.gachaLevel:
        return 'Gachapon level ${e.level ?? e.amount?.toInt() ?? 0}';
      case FacilityEffectType.cookingEfficiencyBonus:
        return '+${e.percent?.toStringAsFixed(0) ?? amountStr}% cooking speed';
      case FacilityEffectType.friendLimitIncrease:
        return '+${e.amount?.toInt() ?? 0} friends limit';
      case FacilityEffectType.storageIncrease:
        return '+${e.amount?.toInt() ?? 0} storage';
      case FacilityEffectType.ordersIncrease:
        return '+${e.amount?.toInt() ?? 0} orders';
    }
  }
}
