import 'package:flutter/material.dart';
import '../model/battle_pass.dart';

class BattlePassRewardBox extends StatelessWidget {
  final List<BattlePassReward> rewards;
  final bool isSuper;

  const BattlePassRewardBox({
    super.key,
    required this.rewards,
    this.isSuper = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Text('—');
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isSuper ? Colors.black26 : Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: rewards.map((r) => _chip(context, r)).toList(),
      ),
    );
  }

  Widget _chip(BuildContext context, BattlePassReward r) {
    final (icon, label) = _iconAndLabel(r);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  (IconData, String) _iconAndLabel(BattlePassReward r) {
    switch (r.type) {
      case BattlePassRewardType.facility:
        return (Icons.store, _titleizeId(r.id ?? 'facility'));
      case BattlePassRewardType.memento:
        return (Icons.card_giftcard, _titleizeId(r.id ?? 'memento'));
      case BattlePassRewardType.currency:
        return (Icons.attach_money, '${_cur(r.currency)}+${r.amount ?? 0}');
      case BattlePassRewardType.rating:
        return (Icons.star, 'Rating+${r.rating ?? 0}');
      case BattlePassRewardType.item:
        final qty = r.qty ?? 1;
        final lvl = r.level;
        final name = _titleizeId(r.id ?? 'item');
        if (lvl != null) return (Icons.inventory_2, '${qty}x $name (Lv.$lvl)');
        return (Icons.inventory_2, '${qty}x $name');
      case BattlePassRewardType.gachaDraw:
        return (Icons.casino, 'Gacha Draw ${r.amount ?? 0}');
      case BattlePassRewardType.promoteFree:
        return (Icons.campaign, '${r.amount ?? 0}x Promote');
      case BattlePassRewardType.chest:
        return (Icons.all_inbox, _titleizeId(r.id ?? 'chest'));
      case BattlePassRewardType.text:
        return (Icons.notes, r.text ?? 'Info');
    }
  }

  String _cur(String? c) {
    if (c == null || c.trim().isEmpty) return 'Currency';
    // keep your underscored ids but make nicer labels
    return _titleizeId(c);
  }

  String _titleizeId(String id) {
    // You said IDs are underscored like teddy_bear_stove_1 — display prettier.
    return id
        .split('_')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
