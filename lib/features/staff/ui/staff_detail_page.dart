import 'package:flutter/material.dart';

import '../model/staff_member.dart';
import '../data/staff_progress.dart';

import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

class StaffDetailPage extends StatefulWidget {
  final StaffMember staff;
  const StaffDetailPage({super.key, required this.staff});

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  final progress = StaffProgress.instance;

  StaffMember get s => widget.staff;

  Set<int> _checked = <int>{};
  int? _highest;

  // Collapse whole "Raise Upgrades" section
  bool _raiseOpen = true;

  // Only one level expanded at a time
  int? _expandedLevel;

  static const String _starAsset = 'assets/images/star.png';
  static String _currencyAsset(String currencyKey) =>
      'assets/images/$currencyKey.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final set = await progress.checkedLevels(s.id);
    final hi = await progress.highestCheckedLevel(s.id);
    if (!mounted) return;
    setState(() {
      _checked = set;
      _highest = hi;
      _expandedLevel ??= hi;
    });
  }

  Future<void> _toggleChecked(int level, bool value) async {
    await progress.setChecked(s.id, level, value);
    await _load();
  }

  StaffRaiseUpgrade? get _currentUpgrade {
    if (_highest == null) return null;
    for (final u in s.raiseUpgrades) {
      if (u.level == _highest) return u;
    }
    return null;
  }

  void _toggleRaiseOpen() {
    setState(() {
      _raiseOpen = !_raiseOpen;
      if (!_raiseOpen) _expandedLevel = null;
    });
  }

  void _toggleLevelExpanded(int level) {
    setState(() {
      _expandedLevel = (_expandedLevel == level) ? null : level;
    });
  }

  Future<void> _openMementoById(String mementoId) async {
    final entry = await MementosIndex.instance.byId(mementoId);
    if (entry == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MementoDetailPage(memento: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentUpgrade;

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        children: [
          _RaiseUpgradesCard(
            title: 'Raise Upgrades',
            icon: Icons.trending_up,
            open: _raiseOpen,
            onToggleOpen: _toggleRaiseOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current == null)
                  Text(
                    'No raise level checked yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  _CurrentPerksBox(
                    current: current,
                    starAsset: _starAsset,
                    currencyAssetFor: _currencyAsset,
                  ),
                const SizedBox(height: 12),
                ...s.raiseUpgrades.map((u) {
                  final isChecked = _checked.contains(u.level);
                  final isExpanded = _expandedLevel == u.level;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => _toggleLevelExpanded(u.level),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Checkbox(
                                        value: isChecked,
                                        onChanged: (v) => _toggleChecked(
                                          u.level,
                                          v ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'LVL ${u.level}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                              ),
                                              Icon(
                                                isExpanded
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if ((u.required ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                                _InlineStat.icon(
                                                  icon: Icons.schedule,
                                                  text: 'Req: ${u.required}',
                                                ),
                                              if (u.ratingBonus != null)
                                                _InlineStat.asset(
                                                  assetPath: _starAsset,
                                                  fallbackIcon: Icons.star,
                                                  text:
                                                      '+${_formatWithCommas(u.ratingBonus!)}',
                                                ),
                                              if (u.cost != null)
                                                _InlineStat.asset(
                                                  assetPath: _currencyAsset(
                                                    u.cost!.currency,
                                                  ),
                                                  fallbackIcon:
                                                      Icons.attach_money,
                                                  text: _formatWithCommas(
                                                    u.cost!.amount,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 180),
                              firstChild: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: _PerksTable(perks: u.perks),
                              ),
                              secondChild: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          if ((s.unlocking ?? '').trim().isNotEmpty)
            _SectionCard(
              title: 'Unlocking',
              icon: Icons.lock_outline,
              child: Text(s.unlocking!),
            ),
          if ((s.job ?? '').trim().isNotEmpty)
            _SectionCard(
              title: 'Job',
              icon: Icons.work_outline,
              child: Text(s.job!),
            ),
          _SectionCard(
            title: 'Wearable Mementos',
            icon: Icons.checkroom_outlined,
            child: s.wearableMementos.isEmpty
                ? const Text('No wearable mementos listed yet.')
                : Column(
                    children: s.wearableMementos.map((wm) {
                      final req = (wm.requirements ?? '').trim();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openMementoById(wm.mementoId),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleizeId(wm.mementoId),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      if (wm.bonusRating != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: _InlineStat.asset(
                                            assetPath: _starAsset,
                                            fallbackIcon: Icons.star,
                                            text:
                                                '+${_formatWithCommas(wm.bonusRating!)}',
                                          ),
                                        ),
                                      if (req.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            req,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RaiseUpgradesCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool open;
  final VoidCallback onToggleOpen;
  final Widget child;

  const _RaiseUpgradesCard({
    required this.title,
    required this.icon,
    required this.open,
    required this.onToggleOpen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              InkWell(
                onTap: onToggleOpen,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Icon(open ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                crossFadeState:
                    open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 180),
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: child,
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CurrentPerksBox extends StatelessWidget {
  final StaffRaiseUpgrade current;
  final String starAsset;
  final String Function(String currencyKey) currencyAssetFor;

  const _CurrentPerksBox({
    required this.current,
    required this.starAsset,
    required this.currencyAssetFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Perks', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineStat.icon(
                icon: Icons.upgrade,
                text: 'LVL ${current.level}',
              ),
              if ((current.required ?? '').trim().isNotEmpty)
                _InlineStat.icon(
                  icon: Icons.schedule,
                  text: 'Req: ${current.required}',
                ),
              if (current.ratingBonus != null)
                _InlineStat.asset(
                  assetPath: starAsset,
                  fallbackIcon: Icons.star,
                  text: '+${_formatWithCommas(current.ratingBonus!)}',
                ),
              if (current.cost != null)
                _InlineStat.asset(
                  assetPath: currencyAssetFor(current.cost!.currency),
                  fallbackIcon: Icons.attach_money,
                  text: _formatWithCommas(current.cost!.amount),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PerksTable(perks: current.perks),
        ],
      ),
    );
  }
}

class _PerksTable extends StatelessWidget {
  final Map<String, String> perks;
  const _PerksTable({required this.perks});

  @override
  Widget build(BuildContext context) {
    if (perks.isEmpty) return const Text('No perks listed.');
    final entries = perks.entries.toList();

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child:
                      Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    e.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  final Widget leading;
  final String text;

  const _InlineStat._({required this.leading, required this.text});

  static _InlineStat icon({required IconData icon, required String text}) {
    return _InlineStat._(
      leading: Icon(icon, size: 18),
      text: text,
    );
  }

  static _InlineStat asset({
    required String assetPath,
    required IconData fallbackIcon,
    required String text,
  }) {
    return _InlineStat._(
      leading: Image.asset(
        assetPath,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 18),
      ),
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, height: 18, child: Center(child: leading)),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

String _titleizeId(String id) {
  final s = id.replaceAll('_', ' ').trim();
  if (s.isEmpty) return id;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

String _formatWithCommas(int value) {
  final s = value.toString();
  final chars = s.split('');
  final out = <String>[];
  int count = 0;

  for (int i = chars.length - 1; i >= 0; i--) {
    out.add(chars[i]);
    count++;
    if (count == 3 && i != 0) {
      out.add(',');
      count = 0;
    }
  }
  return out.reversed.join();
}
