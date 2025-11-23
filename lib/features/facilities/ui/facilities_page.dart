import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/facilities_repository.dart';
import '../model/facility.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final repo = FacilitiesRepository.instance;
  final store = UnlockedStore.instance; // bucket: 'facility'

  // Scenes to show (exclude courtyard variants)
  static const List<FacilityArea> _scenes = [
    FacilityArea.restaurant,
    FacilityArea.kitchen,
    FacilityArea.garden,
    FacilityArea.buffet,
    FacilityArea.takeout,
    FacilityArea.terrace,
  ];

  FacilityArea _selectedScene = FacilityArea.restaurant;
  String? _selectedTheme;

  // current shard future
  late Future<List<Facility>> _future = repo.byArea(_selectedScene);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facilities')),
      body: Column(
        children: [
          _ScenesBar(
            scenes: _scenes,
            selected: _selectedScene,
            onSelect: (s) {
              setState(() {
                _selectedScene = s;
                _selectedTheme = null;
                _future = repo.byArea(_selectedScene); // ✅ load only this shard
              });
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Facility>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load facilities:\n${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final all = (snap.data ?? const <Facility>[]);
                final themes = _themesFor(all);

                final filtered = all.where((f) {
                  if (_selectedTheme != null &&
                      (f.series ?? '') != _selectedTheme) {
                    return false;
                  }
                  return true;
                }).toList();

                final groups =
                    _groupBy<String, Facility>(filtered, (f) => f.group);

                return AnimatedBuilder(
                  animation: store,
                  builder: (context, _) {
                    return Row(
                      children: [
                        _ThemeRail(
                          themes: themes,
                          selected: _selectedTheme,
                          onSelect: (t) => setState(() => _selectedTheme = t),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: (groups.isEmpty)
                              ? const Center(child: Text('No facilities here!'))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      8, 0, 8, 16),
                                  itemCount: groups.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final entry = groups[i];
                                    final items = entry.value
                                      ..sort((a, b) {
                                        final ua = store.isUnlocked(
                                            'facility', a.id);
                                        final ub = store.isUnlocked(
                                            'facility', b.id);
                                        if (ua != ub) {
                                          return ua ? -1 : 1;
                                        }
                                        return a.name.compareTo(b.name);
                                      });
                                    return _FacilityGroupSection(
                                      title: entry.key,
                                      items: items,
                                      store: store,
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _themesFor(List<Facility> all) {
    final set = <String>{};
    for (final f in all) {
      final t = (f.series ?? '').trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<MapEntry<K, List<V>>> _groupBy<K, V>(
      List<V> list, K Function(V) keyFn) {
    final map = <K, List<V>>{};
    final order = <K>[];
    for (final v in list) {
      final k = keyFn(v);
      map.putIfAbsent(k, () {
        order.add(k);
        return <V>[];
      }).add(v);
    }
    return order.map((k) => MapEntry(k, map[k]!)).toList();
  }
}

// ------- UI bits (unchanged labels for enum -> title case) -------

class _ScenesBar extends StatelessWidget {
  const _ScenesBar(
      {required this.scenes, required this.selected, required this.onSelect});
  final List<FacilityArea> scenes;
  final FacilityArea selected;
  final ValueChanged<FacilityArea> onSelect;

  String _label(FacilityArea a) => a.name
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final scene = scenes[i];
          final isSel = selected == scene;
          return ChoiceChip(
            label: Text(_label(scene)),
            selected: isSel,
            onSelected: (_) => onSelect(scene),
          );
        },
      ),
    );
  }
}

class _ThemeRail extends StatelessWidget {
  const _ThemeRail(
      {required this.themes, required this.selected, required this.onSelect});
  final List<String> themes;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('All',
                style: TextStyle(fontWeight: FontWeight.w600)),
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              itemCount: themes.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final t = themes[i];
                return ListTile(
                  dense: true,
                  title: Text(t),
                  selected: selected == t,
                  onTap: () => onSelect(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityGroupSection extends StatelessWidget {
  const _FacilityGroupSection(
      {required this.title, required this.items, required this.store});
  final String title;
  final List<Facility> items;
  final UnlockedStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, c) {
                final crossAxisCount =
                    (c.maxWidth / 160).floor().clamp(1, 6);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final f = items[i];
                    final checked = store.isUnlocked('facility', f.id);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        // 👇 TAP = open detail page
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FacilityDetailPage(facility: f),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    f.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: checked,
                                  // 👇 CHECKBOX = toggle unlocked
                                  onChanged: (v) => store.setUnlocked(
                                      'facility', f.id, v ?? false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// --- Keep everything above unchanged --- //

class FacilityDetailPage extends StatelessWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final store = UnlockedStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Facility Details')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return _FacilityDetailBody(facility: facility, store: store);
        },
      ),
    );
  }
}

class _FacilityDetailBody extends StatelessWidget {
  const _FacilityDetailBody({required this.facility, required this.store});
  final Facility facility;
  final UnlockedStore store;

  @override
  Widget build(BuildContext context) {
    final checked = store.isUnlocked('facility', facility.id);
    final theme = Theme.of(context);
    final prices = facility.price;
    final effects = facility.effects;
    final specials = facility.specialRequirements ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------- Title Row ----------
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
                  store.setUnlocked('facility', facility.id, v ?? false),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---------- Description ----------
        if ((facility.description ?? '').isNotEmpty)
          Text(
            facility.description!,
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),

        // ---------- Info Card ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(context, 'Area',
                    _prettyEnumName(facility.area.name)),
                _infoRow(context, 'Group', facility.group),
                if ((facility.series ?? '').isNotEmpty)
                  _infoRow(context, 'Series', facility.series!),
                _infoRow(
                  context,
                  'Star requirement',
                  facility.requirementStars! > 0
                      ? '${facility.requirementStars}★'
                      : '—',
                ),
                if (prices.isNotEmpty)
                  _infoRow(context, 'Price', _formatPrice(prices.first)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---------- Effects ----------
        if (effects.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effects',
                      style: theme.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...effects.map((e) => _infoRow(context, _effectLabel(e), _effectValue(e))),
                ],
              ),
            ),
          ),

        // ---------- Special Requirements ----------
        if (specials.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Special requirements',
                      style: theme.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...specials.map((s) => Text('• $s')),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- Helper Rows ----------
  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  String _formatPrice(Price price) {
    final amt = _formatNumber(price.amount);
    final cur = price.currency.key;
    return '🐟 $amt $cur';
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

  String _prettyEnumName(String raw) => raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String _effectLabel(FacilityEffect e) {
    switch (e.type) {
      case FacilityEffectType.ratingBonus:
        return 'Rating Bonus';
      case FacilityEffectType.cookingEfficiencyBonus:
        return 'Cooking Efficiency';
      case FacilityEffectType.incomePerMinute:
        return 'Income / min';
      case FacilityEffectType.tipCapIncrease:
        return 'Tip Cap Increase';
      case FacilityEffectType.incomePerInterval:
        return 'Income per Interval';
      case FacilityEffectType.incomePerEventRange:
        return 'Income (Event Range)';
      case FacilityEffectType.gachaDraws:
        return 'Gacha Draws';
      case FacilityEffectType.gachaLevel:
        return 'Gacha Level';
    }
  }

  String _effectValue(FacilityEffect e) {
    final amt = e.amount?.toInt() ?? 0;
    switch (e.type) {
      case FacilityEffectType.ratingBonus:
        return '+$amt';
      case FacilityEffectType.cookingEfficiencyBonus:
        return '+$amt%';
      case FacilityEffectType.tipCapIncrease:
        return '+${e.capIncrease ?? amt}';
      case FacilityEffectType.incomePerMinute:
        return '+$amt ${e.currency?.key ?? ''}/min';
      case FacilityEffectType.incomePerInterval:
        return '+$amt/${e.intervalMinutes ?? 0}min';
      case FacilityEffectType.incomePerEventRange:
        return '${e.min ?? 0}–${e.max ?? amt} ${e.currency?.key ?? ''}';
      case FacilityEffectType.gachaDraws:
        return '${e.amount?.toInt() ?? 0} draws';
      case FacilityEffectType.gachaLevel:
        return 'Lv. ${e.level ?? e.amount?.toInt() ?? 1}';
    }
  }
}
