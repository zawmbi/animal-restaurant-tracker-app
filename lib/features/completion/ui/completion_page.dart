import 'package:flutter/material.dart';
import '../../shared/data/unlocked_store.dart';
import '../../facilities/data/facilities_repository.dart';
import '../../facilities/model/facility.dart';

/// "Cost to complete" — how much currency it takes to own every facility,
/// filterable by scene and group, with a live "remaining" total based on
/// what the player has already checked off.
class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key});
  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  final _repo = FacilitiesRepository.instance;
  final _store = UnlockedStore.instance;
  late Future<List<Facility>> _future;

  FacilityArea? _scene; // null = all scenes
  String? _group; // null = all groups

  @override
  void initState() {
    super.initState();
    _future = _repo.all();
  }

  String _prettyArea(FacilityArea a) => a.name
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String _curName(MoneyCurrency c) =>
      '${c.key[0].toUpperCase()}${c.key.substring(1)}';

  String _fmt(int v) {
    final neg = v < 0;
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return neg ? '-$buf' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost to Complete')),
      body: FutureBuilder<List<Facility>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final all = snap.data!;
          // Rebuild totals whenever ownership changes.
          return AnimatedBuilder(
            animation: _store,
            builder: (context, _) => _content(context, all),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, List<Facility> all) {
    final scenes = <FacilityArea>{for (final f in all) f.area}.toList()
      ..sort((a, b) => _prettyArea(a).compareTo(_prettyArea(b)));

    // groups available for the current scene selection
    final groupPool = all.where((f) => _scene == null || f.area == _scene);
    final groups = <String>{for (final f in groupPool) f.group}.toList()..sort();

    // if the selected group no longer applies, drop it
    if (_group != null && !groups.contains(_group)) _group = null;

    final filtered = all.where((f) {
      if (_scene != null && f.area != _scene) return false;
      if (_group != null && f.group != _group) return false;
      return true;
    }).toList();

    bool owned(Facility f) => _store.isUnlocked('facility', f.id);

    final totalAll = <MoneyCurrency, int>{};
    final totalRemaining = <MoneyCurrency, int>{};
    int ownedCount = 0;
    for (final f in filtered) {
      final isOwned = owned(f);
      if (isOwned) ownedCount++;
      for (final p in f.price) {
        totalAll[p.currency] = (totalAll[p.currency] ?? 0) + p.amount;
        if (!isOwned) {
          totalRemaining[p.currency] =
              (totalRemaining[p.currency] ?? 0) + p.amount;
        }
      }
    }
    final total = filtered.length;
    final pct = total == 0 ? 0.0 : ownedCount / total;

    final currencies = totalAll.keys.toList()
      ..sort((a, b) => totalAll[b]!.compareTo(totalAll[a]!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- filters ----
        Row(
          children: [
            Expanded(
              child: _sceneDropdown(scenes),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _groupDropdown(groups),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---- progress ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owned $ownedCount of $total facilities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(pct * 100).toStringAsFixed(1)}% complete',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ---- cost table ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cost',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  _scene == null
                      ? 'All scenes'
                      : '${_prettyArea(_scene!)}${_group == null ? '' : ' › $_group'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(flex: 3, child: Text('')),
                    Expanded(
                      flex: 3,
                      child: Text('Remaining',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Total',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const Divider(),
                if (currencies.isEmpty)
                  const Text('No priced facilities in this selection.')
                else
                  for (final c in currencies)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(_curName(c))),
                          Expanded(
                            flex: 3,
                            child: Text(_fmt(totalRemaining[c] ?? 0),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(_fmt(totalAll[c] ?? 0),
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledDropdown(String label, Widget dropdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(child: dropdown),
        ),
      ],
    );
  }

  Widget _sceneDropdown(List<FacilityArea> scenes) {
    return _labeledDropdown(
      'Scene',
      DropdownButton<FacilityArea?>(
        value: _scene,
        isExpanded: true,
        items: [
          const DropdownMenuItem<FacilityArea?>(
              value: null, child: Text('All scenes')),
          for (final s in scenes)
            DropdownMenuItem<FacilityArea?>(
                value: s, child: Text(_prettyArea(s))),
        ],
        onChanged: (v) => setState(() {
          _scene = v;
          _group = null;
        }),
      ),
    );
  }

  Widget _groupDropdown(List<String> groups) {
    return _labeledDropdown(
      'Group',
      DropdownButton<String?>(
        value: _group,
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(
              value: null, child: Text('All groups')),
          for (final g in groups)
            DropdownMenuItem<String?>(value: g, child: Text(g)),
        ],
        onChanged: (v) => setState(() => _group = v),
      ),
    );
  }
}
