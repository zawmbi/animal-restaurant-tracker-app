import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../model/staff_member.dart';
import '../data/staff_progress.dart';

import '../../mementos/data/mementos_index.dart';
import '../../mementos/ui/mementos_detail_page.dart';

import '../../customers/data/customers_repository.dart';
import '../../customers/ui/customer_detail_page.dart' as custdetail;

import '../../facilities/data/facilities_repository.dart' as facrepo;
import '../../facilities/ui/facility_detail_page.dart' as facdetail;

// Adjust these imports if your dishes live elsewhere:
import '../../dishes/data/dishes_repository.dart' as dishrepo;
import '../../dishes/ui/dish_detail_page.dart' as dishdetail;

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

  // Collapse the entire Raise Upgrades section
  bool _raiseOpen = true;

  // Only one level expanded at a time
  int? _expandedLevel;

  static const String _starAsset = 'assets/images/star.png';
  static String _currencyAsset(String currencyKey) => 'assets/images/$currencyKey.png';

  final Map<String, String> _customerNameToId = {};
  final Map<String, String> _facilityNameToId = {};
  final Map<String, String> _dishNameToId = {};
  bool _linksLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadEntityLinks();
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

  Future<void> _loadEntityLinks() async {
    try {
      final customers = await CustomersRepository.instance.all();
      for (final c in customers) {
        final name = (c.name ?? '').toString().trim();
        if (name.isNotEmpty) _customerNameToId[name] = c.id;
      }

      final facilities = await facrepo.FacilitiesRepository.instance.all();
      for (final f in facilities) {
        final name = (f.name ?? '').toString().trim();
        if (name.isNotEmpty) _facilityNameToId[name] = f.id;
      }

      // Dishes/Recipes (adjust to your repo + model field names)
      final dishes = await dishrepo.DishesRepository.instance.all();
      for (final d in dishes) {
        final name = (d.name ?? '').toString().trim();
        if (name.isNotEmpty) _dishNameToId[name] = d.id;
      }

      if (!mounted) return;
      setState(() => _linksLoaded = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _linksLoaded = true);
    }
  }

  Future<void> _toggle(int level, bool value) async {
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

  void _toggleLevelExpanded(int level) {
    setState(() {
      _expandedLevel = (_expandedLevel == level) ? null : level;
    });
  }

  Future<void> _openMementoById(String mementoId) async {
    final entry = await MementosIndex.instance.byId(mementoId);
    if (entry == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MementoDetailPage(memento: entry)),
    );
  }

  Future<void> _openCustomerById(String id) async {
    final c = await CustomersRepository.instance.byId(id);
    if (c == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => custdetail.CustomerDetailPage(customer: c)),
    );
  }

  Future<void> _openFacilityById(String id) async {
    final f = await facrepo.FacilitiesRepository.instance.byId(id);
    if (f == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => facdetail.FacilityDetailPage(facilityId: f.id),
      ),
    );
  }

  Future<void> _openDishById(String id) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => dishdetail.DishDetailPage(dishId: id),
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
          if ((s.job ?? '').trim().isNotEmpty)
            _SectionCard(
              title: 'Job',
              icon: Icons.work_outline,
              child: _LinkedText(
                text: s.job!,
                linksLoaded: _linksLoaded,
                customerNameToId: _customerNameToId,
                facilityNameToId: _facilityNameToId,
                dishNameToId: _dishNameToId,
                onCustomerTap: _openCustomerById,
                onFacilityTap: _openFacilityById,
                onDishTap: _openDishById,
              ),
            ),
          _CollapsibleSectionCard(
            title: 'Raise Upgrades',
            icon: Icons.trending_up,
            initiallyExpanded: _raiseOpen,
            onChanged: (open) {
              setState(() {
                _raiseOpen = open;
                if (!open) _expandedLevel = null;
              });
            },
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
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => _toggleLevelExpanded(u.level),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Checkbox(
                                        value: isChecked,
                                        onChanged: (v) => _toggle(u.level, v ?? false),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'LVL ${u.level}',
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 18,
                                            runSpacing: 6,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              if ((u.required ?? '').trim().isNotEmpty)
                                                _InlineStat.icon(
                                                  icon: Icons.schedule,
                                                  text: 'Required: ${u.required}',
                                                ),
                                              if (u.ratingBonus != null)
                                                _InlineStat.asset(
                                                  assetPath: _starAsset,
                                                  fallbackIcon: Icons.star,
                                                  text: '+${_formatWithCommas(u.ratingBonus!.toString())}',
                                                ),
                                              if (u.cost != null)
                                                _InlineStat.asset(
                                                  assetPath: _currencyAsset(u.cost!.currency),
                                                  fallbackIcon: Icons.attach_money,
                                                  text: _formatWithCommas(u.cost!.amount.toString()),
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
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              child: _LinkedText(
                text: s.unlocking!,
                linksLoaded: _linksLoaded,
                customerNameToId: _customerNameToId,
                facilityNameToId: _facilityNameToId,
                dishNameToId: _dishNameToId,
                onCustomerTap: _openCustomerById,
                onFacilityTap: _openFacilityById,
                onDishTap: _openDishById,
              ),
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
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Only THIS header row opens the memento
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openMementoById(wm.mementoId),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _titleizeId(wm.mementoId),
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),

                              if (wm.bonusRating != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _InlineStat.asset(
                                    assetPath: _starAsset,
                                    fallbackIcon: Icons.star,
                                    text: '+${_formatWithCommas(wm.bonusRating!.toString())}',
                                  ),
                                ),

                              // Requirements text with clickable links
                              if (req.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _LinkedText(
                                    text: req,
                                    linksLoaded: _linksLoaded,
                                    customerNameToId: _customerNameToId,
                                    facilityNameToId: _facilityNameToId,
                                    dishNameToId: _dishNameToId,
                                    onCustomerTap: _openCustomerById,
                                    onFacilityTap: _openFacilityById,
                                    onDishTap: _openDishById,
                                    small: true,
                                  ),
                                ),
                            ],
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

class _LinkedText extends StatelessWidget {
  final String text;
  final bool linksLoaded;

  final Map<String, String> customerNameToId;
  final Map<String, String> facilityNameToId;
  final Map<String, String> dishNameToId;

  final Future<void> Function(String customerId) onCustomerTap;
  final Future<void> Function(String facilityId) onFacilityTap;
  final Future<void> Function(String dishId) onDishTap;

  final bool small;

  const _LinkedText({
    required this.text,
    required this.linksLoaded,
    required this.customerNameToId,
    required this.facilityNameToId,
    required this.dishNameToId,
    required this.onCustomerTap,
    required this.onFacilityTap,
    required this.onDishTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!linksLoaded) {
      return Text(
        text,
        style: small ? Theme.of(context).textTheme.bodySmall : null,
      );
    }

    final baseStyle = small
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    final linkStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationThickness: 1.2,
    );

    final matches = _collectMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          if (m.kind == _LinkKind.customer) {
            onCustomerTap(m.id);
          } else if (m.kind == _LinkKind.facility) {
            onFacilityTap(m.id);
          } else if (m.kind == _LinkKind.dish) {
            onDishTap(m.id);
          }
        };

      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: linkStyle,
          recognizer: recognizer,
        ),
      );

      cursor = m.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }

  List<_TextMatch> _collectMatches(String full) {
    final all = <_TextMatch>[];

    void addMatches(Map<String, String> map, _LinkKind kind) {
      final names = map.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      for (final name in names) {
        if (name.trim().isEmpty) continue;
        final re = RegExp(RegExp.escape(name), caseSensitive: false);
        for (final m in re.allMatches(full)) {
          all.add(
            _TextMatch(
              start: m.start,
              end: m.end,
              id: map[name]!,
              kind: kind,
              len: m.end - m.start,
            ),
          );
        }
      }
    }

    addMatches(customerNameToId, _LinkKind.customer);
    addMatches(facilityNameToId, _LinkKind.facility);
    addMatches(dishNameToId, _LinkKind.dish);

    if (all.isEmpty) return const [];

    all.sort((a, b) {
      if (a.start != b.start) return a.start.compareTo(b.start);
      return b.len.compareTo(a.len);
    });

    final picked = <_TextMatch>[];
    int lastEnd = -1;
    for (final m in all) {
      if (m.start < lastEnd) continue;
      picked.add(m);
      lastEnd = m.end;
    }

    return picked;
  }
}

enum _LinkKind { customer, facility, dish }

class _TextMatch {
  final int start;
  final int end;
  final String id;
  final _LinkKind kind;
  final int len;

  const _TextMatch({
    required this.start,
    required this.end,
    required this.id,
    required this.kind,
    required this.len,
  });
}

class _CollapsibleSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool> onChanged;

  const _CollapsibleSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.initiallyExpanded,
    required this.onChanged,
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
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              onExpansionChanged: onChanged,
              tilePadding: const EdgeInsets.all(12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              children: [child],
            ),
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
            spacing: 18,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineStat.icon(icon: Icons.upgrade, text: 'LVL ${current.level}'),
              if ((current.required ?? '').trim().isNotEmpty)
                _InlineStat.icon(icon: Icons.schedule, text: 'Req: ${current.required}'),
              if (current.ratingBonus != null)
                _InlineStat.asset(
                  assetPath: starAsset,
                  fallbackIcon: Icons.star,
                  text: '+${_formatWithCommas(current.ratingBonus!.toString())}',
                ),
              if (current.cost != null)
                _InlineStat.asset(
                  assetPath: currencyAssetFor(current.cost!.currency),
                  fallbackIcon: Icons.attach_money,
                  text: _formatWithCommas(current.cost!.amount.toString()),
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
                  child: Text(e.key, style: Theme.of(context).textTheme.bodySmall),
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

String _formatWithCommas(String digitsOnly) {
  final chars = digitsOnly.split('');
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
