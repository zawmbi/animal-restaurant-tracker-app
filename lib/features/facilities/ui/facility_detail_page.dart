import 'package:flutter/material.dart';

import '../../completion/data/progress_types.dart';
import '../../economy/data/income_repository.dart';
import '../../economy/data/terrace_observation_store.dart';
import '../../economy/logic/terrace_pay_projection.dart';
import '../../economy/model/income.dart';
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

class FacilityDetailPage extends StatefulWidget {
  const FacilityDetailPage({super.key, required this.facilityId});

  final String facilityId;

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  /// Built once. It used to be created inside `build()`, which meant every
  /// rebuild kicked off a fresh load and dropped the page back to a spinner.
  late final Future<_DetailData> _data = _load(widget.facilityId);

  /// Loads the facility plus everything the income and terrace cards need.
  ///
  /// The terrace sibling list is only fetched for terrace facilities, because
  /// it is the one area whose card has to weigh this facility against the other
  /// 88 that share its channel.
  static Future<_DetailData> _load(String facilityId) async {
    final repo = FacilitiesRepository.instance;
    final facility = await repo.byId(facilityId);

    await IncomeRepository.instance.ensureLoaded();
    await TerraceObservationStore.instance.ensureLoaded();

    final terrace = facility?.area == FacilityArea.terrace
        ? await repo.byArea(FacilityArea.terrace)
        : const <Facility>[];

    return _DetailData(facility: facility, terraceFacilities: terrace);
  }

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Facility Details')),
      body: FutureBuilder<_DetailData>(
        future: _data,
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

          final facility = snap.data?.facility;
          if (facility == null) {
            return const Center(child: Text('Facility not found.'));
          }

          // Rebuild when unlock state changes so the checkbox updates — and so
          // does the terrace card, whose whole job is to compare this facility
          // against what is ticked.
          return AnimatedBuilder(
            animation: Listenable.merge(
              <Listenable>[store, TerraceObservationStore.instance],
            ),
            builder: (context, _) => _FacilityDetailBody(
              facility: facility,
              store: store,
              terraceFacilities: snap.data!.terraceFacilities,
            ),
          );
        },
      ),
    );
  }
}

class _DetailData {
  const _DetailData({required this.facility, required this.terraceFacilities});

  final Facility? facility;
  final List<Facility> terraceFacilities;
}

class _FacilityDetailBody extends StatelessWidget {
  const _FacilityDetailBody({
    required this.facility,
    required this.store,
    required this.terraceFacilities,
  });

  final Facility facility;
  final UnlockedStore store;

  /// Every terrace facility, for the pay-bonus card. Empty off the terrace.
  final List<Facility> terraceFacilities;

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

        // ---------- Income effects, from income.json ----------
        // These were loaded and used by the Bank page but never shown here, so
        // a table's whole reason for existing — what it does to your takings —
        // was invisible on its own page.
        ..._incomeSection(context),

        // ---------- Terrace "customers pay" projection ----------
        ..._terracePaySection(context),

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

  // ---------- Income + terrace sections ----------

  bool get _isTerracePayFacility =>
      facility.area == FacilityArea.terrace &&
      kTerracePayGroups.contains(facility.group);

  List<Widget> _incomeSection(BuildContext context) {
    final entries = IncomeRepository.instance.forFacility(facility.id);

    // The terrace card below states the pay bonus itself, so listing it here
    // as well would print the same number twice under two headings.
    final shown = entries
        .where((e) =>
            !(_isTerracePayFacility &&
                (e.channel == IncomeChannel.terracePayFlat ||
                    e.channel == IncomeChannel.terracePayPercent)))
        .toList();

    if (shown.isEmpty) return const <Widget>[];

    final theme = Theme.of(context);
    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Income', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...shown.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('\u2022 ${_formatIncome(e)}'),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _terracePaySection(BuildContext context) {
    if (!_isTerracePayFacility) return const <Widget>[];

    final projection = buildTerracePayProjection(
      facility: facility,
      terraceFacilities: terraceFacilities,
      unlockedIds: store.ids(ProgressTypes.facilityBucketFor(facility.area.name)),
      income: IncomeRepository.instance,
    );
    if (projection.effect.isEmpty) return const <Widget>[];

    final theme = Theme.of(context);
    final effect = projection.effect;
    final observed = TerraceObservationStore.instance.codPerGather;

    final rows = <Widget>[];

    // What this one does.
    if (effect.percent > 0) {
      rows.add(_infoRow(context, 'This table',
          'Customers pay +${_formatDouble(effect.percent)}% more'));
    }
    if (effect.flatCod > 0) {
      rows.add(_infoRow(context, 'This table',
          'Customers pay +${_formatNumber(effect.flatCod.round())} cod'));
    }

    // What you already have.
    rows.add(_infoRow(
      context,
      'Already unlocked',
      '${projection.ownedCount} of ${projection.totalCount} pay tables',
    ));
    if (projection.ownedPercent > 0 || projection.ownedFlatCod > 0) {
      rows.add(_infoRow(
        context,
        'Your bonus now',
        _payTotalText(projection.ownedFlatCod, projection.ownedPercent),
      ));
    }

    if (!projection.alreadyUnlocked) {
      rows.add(_infoRow(
        context,
        'With this one',
        _payTotalText(projection.afterFlatCod, projection.afterPercent),
      ));
    }

    final uplift = projection.percentUpliftFraction;
    final children = <Widget>[
      Text('Customers pay', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      ...rows,
    ];

    if (projection.alreadyUnlocked) {
      children
        ..add(const SizedBox(height: 8))
        ..add(Text(
          'Already ticked off, so it is counted in the totals above rather '
          'than added to them.',
          style: theme.textTheme.bodySmall,
        ));
    } else if (uplift != null) {
      children
        ..add(const Divider(height: 24))
        ..add(Text(
          'Buying this raises your terrace takings by '
          '${_formatDouble(uplift * 100)}%.',
          style: theme.textTheme.titleSmall,
        ))
        ..add(const SizedBox(height: 4));
      if (projection.ownedPercent > 0) {
        children.add(Text(
          'Not the +${_formatDouble(effect.percent)}% on the label: that is '
          'added to the ${_formatDouble(projection.ownedPercent)}% you already '
          'have, so it lifts a '
          '${_formatDouble(100 + projection.ownedPercent)}% payment to '
          '${_formatDouble(100 + projection.afterPercent)}%. The bigger your '
          'terrace, the less each new table moves it.',
          style: theme.textTheme.bodySmall,
        ));
      }

      final extra = projection.extraCodPerGather(observed);
      if (extra != null) {
        children
          ..add(const SizedBox(height: 8))
          ..add(_infoRow(context, 'On your ${_formatNumber(observed.round())} '
              'cod gather', '+${_formatNumber(extra.round())} cod'));
      } else {
        children
          ..add(const SizedBox(height: 8))
          ..add(Text(
            'Record what one gather actually pays you on the Bank page and '
            'this will show the gain in cod.',
            style: theme.textTheme.bodySmall,
          ));
      }
    } else if (projection.addedFlatCod > 0) {
      children
        ..add(const Divider(height: 24))
        ..add(Text(
          'Buying this adds +${_formatNumber(projection.addedFlatCod.round())} '
          'cod to what each terrace customer pays.',
          style: theme.textTheme.titleSmall,
        ))
        ..add(const SizedBox(height: 4))
        ..add(Text(
          'It cannot be turned into a per-gather figure here: the game does '
          'not publish how many customers a terrace gather brings, so '
          'multiplying it out would be inventing a number.',
          style: theme.textTheme.bodySmall,
        ));
    }

    children
      ..add(const SizedBox(height: 8))
      ..add(Text(
        'Unlocked facilities all count, whether or not this is the one on '
        'display, so these add up across every Gathering Table, Table 1 and '
        'Table 2 you own. Assumes the percentages add rather than compound — '
        'the wiki implies it, the game never says so.',
        style: theme.textTheme.bodySmall,
      ));

    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  String _payTotalText(double flatCod, double percent) {
    final parts = <String>[];
    if (percent > 0) parts.add('+${_formatDouble(percent)}%');
    if (flatCod > 0) parts.add('+${_formatNumber(flatCod.round())} cod');
    return parts.isEmpty ? 'None yet' : parts.join('  and  ');
  }

  static String _formatDouble(double v) {
    // Round before testing for a whole number: an uplift of 0.05 comes back
    // from the division as 5.000000000000004, which printed as "5.0%".
    final rounded = (v * 10).roundToDouble() / 10;
    if (rounded % 1 == 0) return _formatNumber(rounded.round());
    return rounded.toStringAsFixed(1);
  }

  String _formatIncome(IncomeEntry e) {
    final cur = e.currency?.key ?? 'cod';
    final amount = e.amount == null ? '' : _formatNumber(e.amount!.round());
    switch (e.channel) {
      case IncomeChannel.tipCap:
        return 'Tip jar capacity +$amount $cur';
      case IncomeChannel.tipPerMinute:
        return '+$amount $cur per minute into the tip jar';
      case IncomeChannel.buffetCodPerHour:
        return '+$amount $cur per hour from the buffet';
      case IncomeChannel.buffetPlatesPerDay:
        return '+$amount plates per day';
      case IncomeChannel.codPerSeconds:
        return '+$amount $cur every ${e.seconds ?? 0}s while the game is open';
      case IncomeChannel.codPerPurchase:
        return '+$amount $cur on each restaurant purchase';
      case IncomeChannel.codPerFlowerView:
        return '+$amount $cur each time a terrace customer views a flower';
      case IncomeChannel.terracePayFlat:
        return 'Terrace customers pay +$amount $cur';
      case IncomeChannel.terracePayPercent:
        return 'Terrace customers pay +${_formatDouble(e.percent ?? 0)}% more';
      case IncomeChannel.codPerGather:
      case IncomeChannel.filmPerGather:
        final unit = e.channel == IncomeChannel.codPerGather ? cur : 'film';
        final min = _formatNumber((e.min ?? 0).round());
        final max = e.max == null ? null : _formatNumber(e.max!.round());
        return '${max == null ? min : '$min\u2013$max'} $unit per courtyard gather';
      case IncomeChannel.bottlesPerDay:
        return '+$amount free bottles per day';
      case IncomeChannel.tableRefreshes:
        return '+$amount free table refreshes per day';
      case IncomeChannel.takeoutOrders:
        return '+$amount takeout orders per day';
      case IncomeChannel.takeoutCapacity:
        return '+$amount takeout storage';
      case IncomeChannel.counterCapacity:
        return '+$amount counter capacity';
      case IncomeChannel.cookingEfficiencyPercent:
        return '+${_formatDouble(e.percent ?? 0)}% cooking speed';
      default:
        // Every other channel is either summarised on the Bank page or has a
        // unit that needs more context than this line can carry.
        final pct = e.percent;
        if (pct != null) return '+${_formatDouble(pct)}% ${e.channel.name}';
        return '+$amount ${e.channel.name}';
    }
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
