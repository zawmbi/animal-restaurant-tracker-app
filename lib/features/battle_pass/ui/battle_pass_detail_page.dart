import 'package:flutter/material.dart';

import '../../facilities/data/facilities_repository.dart';
import '../../facilities/ui/facility_detail_page.dart' as facdetail;

import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

import '../../shared/data/unlocked_store.dart';
import '../model/battle_pass.dart';

class BattlePassDetailPage extends StatefulWidget {
  final BattlePass pass;
  const BattlePassDetailPage({super.key, required this.pass});

  @override
  State<BattlePassDetailPage> createState() => _BattlePassDetailPageState();
}

class _BattlePassDetailPageState extends State<BattlePassDetailPage> {
  final store = UnlockedStore.instance;

  int _phaseIndex = 0;

  BattlePass get pass => widget.pass;
  BattlePassPhase get phase => pass.phases[_phaseIndex];

  String _claimKey({
    required String track, // normal or super
    required int exp,
  }) =>
      'bp:${pass.id}:${phase.id}:$track:$exp';

  // Currency images: assets/images/<currencyKey>.png
  // Examples: assets/images/diamonds.png, cod.png, film.png, plate.png, bell.png
// Currency images: assets/images/<currencyKey>.png
// We normalize common variants from data -> your asset naming.
static String _currencyAsset(String currencyKey) {
  final k = currencyKey.trim().toLowerCase();

  const aliases = <String, String>{
    // plural -> singular
    'plates': 'plate',
    'bells': 'bell',
    'diamonds': 'diamond',

    // if your data ever uses these variants
    'films': 'film',
    'codes': 'cod',
  };

  final normalized = aliases[k] ?? k;
  return 'assets/images/$normalized.png';
}

  static const String _starAsset = 'assets/images/star.png';

  // Optional: if you add these PNGs it will use them; otherwise it falls back to icons
  static const String _gachaAsset = 'assets/images/gachapon.png';
  static const String _promoteAsset = 'assets/images/promote.png';

  // Resolved names for the current phase only
  late Future<_ResolvedNames> _namesFuture = _loadNamesForPhase(phase);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(pass.name)),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return FutureBuilder<_ResolvedNames>(
            future: _namesFuture,
            builder: (context, snap) {
              final resolved = snap.data ?? const _ResolvedNames.empty();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overview', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(pass.overview),
                          if (pass.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Notes', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ...pass.notes.map((n) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• $n'),
                                )),
                          ],
                          if (pass.eventRule.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Event Rule',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(pass.eventRule),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Phase picker
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              value: _phaseIndex,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (int i = 0; i < pass.phases.length; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(pass.phases[i].name),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _phaseIndex = v;
                                  _namesFuture = _loadNamesForPhase(phase);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Phase header + dates
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(phase.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          if (phase.start.isNotEmpty || phase.end.isNotEmpty)
                            Text('Runs: ${phase.start} → ${phase.end}'),
                          if (phase.completionNote.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(phase.completionNote),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rewards list
                  ...phase.tiers.map((tier) {
                    final normalKey =
                        _claimKey(track: 'normal', exp: tier.exp);
                    final superKey = _claimKey(track: 'super', exp: tier.exp);

                    final normalClaimed =
                        store.isUnlocked('battle_pass_claimed', normalKey);
                    final superClaimed =
                        store.isUnlocked('battle_pass_claimed', superKey);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Event EXP ${tier.exp}',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 10),
                            _trackBox(
                              context,
                              title: 'Normal Rewards',
                              claimed: normalClaimed,
                              onToggle: (v) => store.setUnlocked(
                                'battle_pass_claimed',
                                normalKey,
                                v,
                              ),
                              rewards: tier.normalRewards,
                              resolved: resolved,
                            ),
                            const SizedBox(height: 10),
                            _trackBox(
                              context,
                              title: 'Super Rewards',
                              claimed: superClaimed,
                              onToggle: (v) => store.setUnlocked(
                                'battle_pass_claimed',
                                superKey,
                                v,
                              ),
                              rewards: tier.superRewards,
                              resolved: resolved,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _trackBox(
    BuildContext context, {
    required String title,
    required bool claimed,
    required ValueChanged<bool> onToggle,
    required List<BattlePassReward> rewards,
    required _ResolvedNames resolved,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              Checkbox(
                value: claimed,
                onChanged: (v) => onToggle(v ?? false),
              ),
            ],
          ),
          if (rewards.isEmpty)
            const Text('—')
          else
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  rewards.map((r) => _rewardChip(context, r, resolved)).toList(),
            ),
        ],
      ),
    );
  }

  //  Facility + Memento clickable + show real names.
  //  Currency/consumables show PNG + amount only, NOT clickable.
  Widget _rewardChip(
      BuildContext context, BattlePassReward r, _ResolvedNames resolved) {
    final isClickable = r.type == BattlePassRewardType.facility ||
        r.type == BattlePassRewardType.memento;

    final avatar = _rewardAvatar(r);
    final label = _rewardLabel(r, resolved);

    if (isClickable) {
      return ActionChip(
        avatar: avatar,
        label: Text(label),
        onPressed: () => _openReward(context, r),
      );
    }

    return Chip(
      avatar: avatar,
      label: Text(label),
    );
  }

  //  PNGs for currency/rating (and optional PNGs for gacha/promote)
  Widget _rewardAvatar(BattlePassReward r) {
    switch (r.type) {
      case BattlePassRewardType.currency: {
        final cur = (r.currency ?? '').trim();
        if (cur.isEmpty) return const Icon(Icons.attach_money, size: 18);

        return Image.asset(
          _currencyAsset(cur),
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.attach_money, size: 18),
        );
      }

      case BattlePassRewardType.rating:
        return Image.asset(
          _starAsset,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 18),
        );

      case BattlePassRewardType.gachaDraw:
        return Image.asset(
          _gachaAsset,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.casino, size: 18),
        );

      case BattlePassRewardType.promoteFree:
        return Image.asset(
          _promoteAsset,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.campaign, size: 18),
        );

      case BattlePassRewardType.facility:
        return const Icon(Icons.store, size: 18);

      case BattlePassRewardType.memento:
        return const Icon(Icons.card_giftcard, size: 18);

      case BattlePassRewardType.item:
        return const Icon(Icons.inventory_2, size: 18);

      case BattlePassRewardType.chest:
        return const Icon(Icons.all_inbox, size: 18);

      case BattlePassRewardType.text:
        return const Icon(Icons.notes, size: 18);
    }
  }

  String _rewardLabel(BattlePassReward r, _ResolvedNames resolved) {
    switch (r.type) {
      case BattlePassRewardType.facility: {
        final id = r.id ?? '';
        final name = resolved.facilityNameById[id];
        return (name != null && name.trim().isNotEmpty) ? name : (id.isEmpty ? 'Facility' : id);
      }

      case BattlePassRewardType.memento: {
        final id = r.id ?? '';
        final name = resolved.mementoNameById[id];
        return (name != null && name.trim().isNotEmpty) ? name : (id.isEmpty ? 'Memento' : id);
      }

      //  Show amount only (image conveys currency)
      // If currency image is missing, show "+amount currency" as fallback.
      case BattlePassRewardType.currency: {
        final a = r.amount ?? 0;
        final cur = (r.currency ?? '').trim();
        final amountOnly = '+${_formatNumber(a)}';

        // We can't know at label-time if the asset exists, but:
        // If currency key is empty, show just amount.
        if (cur.isEmpty) return amountOnly;

        // Prefer amount only (you asked), currency image will show.
        return amountOnly;
      }

      case BattlePassRewardType.rating:
        return 'Rating+${r.rating ?? 0}';

      case BattlePassRewardType.item: {
        final qty = r.qty ?? 1;
        final lvl = r.level;
        final t = r.id ?? 'item';
        if (lvl != null) return '${qty}x $t (Lv.$lvl)';
        return '${qty}x $t';
      }

      case BattlePassRewardType.gachaDraw:
        return '+${r.amount ?? 0}';

      case BattlePassRewardType.promoteFree:
        return '+${r.amount ?? 0}';

      case BattlePassRewardType.chest:
        return r.id ?? 'Chest';

      case BattlePassRewardType.text:
        return r.text ?? 'Info';
    }
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

  Future<void> _openReward(BuildContext context, BattlePassReward r) async {
    if (r.type == BattlePassRewardType.facility && r.id != null) {
      final f = await FacilitiesRepository.instance.byId(r.id!);
      if (!mounted) return;
      if (f == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facility not found: ${r.id}')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => facdetail.FacilityDetailPage(facilityId: f.id),
        ),
      );
      return;
    }

    if (r.type == BattlePassRewardType.memento && r.id != null) {
      final entry = await MementosIndex.instance.byId(r.id!);
      if (!mounted) return;
      if (entry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Memento not found: ${r.id}')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MementoDetailPage(memento: entry)),
      );
      return;
    }

    // Not clickable types shouldn't reach here now.
  }

  Future<_ResolvedNames> _loadNamesForPhase(BattlePassPhase phase) async {
    final facIds = <String>{};
    final memIds = <String>{};

    for (final tier in phase.tiers) {
      for (final r in tier.normalRewards) {
        if (r.type == BattlePassRewardType.facility && r.id != null) facIds.add(r.id!);
        if (r.type == BattlePassRewardType.memento && r.id != null) memIds.add(r.id!);
      }
      for (final r in tier.superRewards) {
        if (r.type == BattlePassRewardType.facility && r.id != null) facIds.add(r.id!);
        if (r.type == BattlePassRewardType.memento && r.id != null) memIds.add(r.id!);
      }
    }

    final facilityNameById = <String, String>{};
    final mementoNameById = <String, String>{};

    // Facilities
    for (final id in facIds) {
      final f = await FacilitiesRepository.instance.byId(id);
      if (f != null) facilityNameById[id] = f.name;
    }

    // Mementos
    for (final id in memIds) {
      final m = await MementosIndex.instance.byId(id);
      if (m != null) mementoNameById[id] = m.name;
    }

    return _ResolvedNames(
      facilityNameById: facilityNameById,
      mementoNameById: mementoNameById,
    );
  }
}

class _ResolvedNames {
  final Map<String, String> facilityNameById;
  final Map<String, String> mementoNameById;

  const _ResolvedNames({
    required this.facilityNameById,
    required this.mementoNameById,
  });

  const _ResolvedNames.empty()
      : facilityNameById = const {},
        mementoNameById = const {};
}
