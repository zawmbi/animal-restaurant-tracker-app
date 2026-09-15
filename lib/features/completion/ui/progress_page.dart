import 'package:flutter/material.dart';

import '../../aromatic_acorn/ui/aromatic_acorn_page.dart';
import '../../battle_pass/ui/battle_pass_page.dart';
import '../../courtyard/ui/courtyard_page.dart';
import '../../customers/ui/booth_owners_page.dart';
import '../../customers/ui/posters_page.dart';
import '../../customers/ui/customers_page.dart';
import '../../dishes/ui/dishes_page.dart';
import '../../facilities/ui/facilities_page.dart';
import '../../letters/ui/letters_page.dart';
import '../../mementos/ui/mementos_page.dart';
import '../../movies/ui/movies_page.dart';
import '../../pets/ui/pets_page.dart';
import '../../shared/data/unlocked_store.dart';
import '../../shared/widgets/check_all_button.dart';
import '../../staff/ui/staff_page.dart';
import '../data/completion_service.dart';

/// One category's numbers for the current build.
class _Row {
  const _Row(this.category, this.collected, this.total);

  final CompletionCategory category;
  final int collected;
  final int total;

  double get fraction => total == 0 ? 0 : collected / total;
  bool get isStarted => collected > 0;
  bool get isComplete => total > 0 && collected == total;
}

/// Global "% complete" across every trackable set in the app.
///
/// Weighting: every individual collectible counts once and counts the same, so
/// the overall number is simply (everything you have checked) / (everything
/// there is). The big sets therefore dominate honestly — the header says so.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _store = UnlockedStore.instance;
  late Future<CompletionData> _future;

  @override
  void initState() {
    super.initState();
    // Totals are parsed once and cached by the service.
    _future = CompletionService.instance.load();
  }

  String _pct(double fraction) => '${(fraction * 100).toStringAsFixed(1)}%';

  Widget? _pageFor(String key) {
    switch (key) {
      case 'customers':
        return const CustomersPage();
      case 'mementos':
        return const MementosPage();
      case 'recipes':
        return const DishesPage();
      case 'letters':
        return const LettersPage();
      case 'facilities':
        return const FacilitiesPage();
      case 'courtyard':
        return const CourtyardPage();
      case 'pets':
        return const PetsPage();
      case 'staff':
        return const StaffPage();
      case 'movies':
        return const MoviesPage();
      case 'battle_pass':
        return const BattlePassPage();
      case 'aromatic_acorn':
        return const AromaticAcornPage();
      case 'booth_owners':
        return const BoothOwnersPage();
      case 'posters':
        return const PostersPage();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overall Completion')),
      body: FutureBuilder<CompletionData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not work out your completion.\n${snap.error ?? ''}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snap.data!;

          // Recount whenever anything is checked off anywhere in the app.
          return AnimatedBuilder(
            animation: _store,
            builder: (context, _) => _content(context, data),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, CompletionData data) {
    final rows = <_Row>[
      for (final c in data.categories)
        _Row(c, c.collected(_store), c.total(_store)),
    ];

    final overallCollected = data.overallCollected(_store);
    final overallTotal = data.overallTotal(_store);
    final overall = data.overallFraction(_store);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _overallCard(context, overall, overallCollected, overallTotal),
        const SizedBox(height: 12),
        _nextStepsCard(context, rows),
        const SizedBox(height: 12),
        Text(
          'By category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final row in rows) _categoryCard(context, row),
      ],
    );
  }

  Widget _overallCard(
    BuildContext context,
    double overall,
    int collected,
    int total,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pct(overall),
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'complete overall',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overall,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$collected of $total collectibles checked off',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Every collectible counts once and counts the same, so the '
              'biggest sets move this number the most.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Beginner help: what is worth doing next.
  Widget _nextStepsCard(BuildContext context, List<_Row> rows) {
    final theme = Theme.of(context);

    // Only real, loadable sets, and never a set that is a subset of another
    // (booth owners) — otherwise the same work gets suggested twice.
    final live = rows
        .where((r) =>
            r.category.isAvailable &&
            r.category.countsTowardTotal &&
            r.total > 0)
        .toList(growable: false);

    final almost = live
        .where((r) => r.isStarted && !r.isComplete && r.fraction >= 0.8)
        .toList()
      ..sort((a, b) => b.fraction.compareTo(a.fraction));

    final notStarted = live.where((r) => !r.isStarted).toList()
      ..sort((a, b) => a.total.compareTo(b.total));

    final done = live.where((r) => r.isComplete).toList(growable: false);

    final lines = <Widget>[];

    if (live.every((r) => !r.isStarted)) {
      lines.add(const Text(
        'Nothing is tracked yet. Pick a category below, open it, and use '
        '"Check all" on anything you have already finished — then keep the '
        'rest ticked off as you go.',
      ));
    } else {
      if (almost.isNotEmpty) {
        lines.add(Text('Almost done', style: theme.textTheme.titleSmall));
        for (final r in almost.take(3)) {
          lines.add(Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${r.category.label} — ${r.total - r.collected} to go '
              '(${_pct(r.fraction)})',
            ),
          ));
        }
      }
      if (notStarted.isNotEmpty) {
        if (lines.isNotEmpty) lines.add(const SizedBox(height: 12));
        lines.add(Text('Not started yet', style: theme.textTheme.titleSmall));
        for (final r in notStarted.take(3)) {
          lines.add(Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${r.category.label} — ${r.total} to track'),
          ));
        }
      }
      if (done.isNotEmpty) {
        if (lines.isNotEmpty) lines.add(const SizedBox(height: 12));
        lines.add(Text(
          'Finished: ${done.map((r) => r.category.label).join(', ')}.',
          style: theme.textTheme.bodySmall,
        ));
      }
      if (lines.isEmpty) {
        lines.add(const Text(
          'Everything is under way. Keep chipping at the categories below.',
        ));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What to do next', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...lines,
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(BuildContext context, _Row row) {
    final theme = Theme.of(context);
    final category = row.category;
    final page = _pageFor(category.key);

    Widget body;
    if (!category.isAvailable) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.label, style: theme.textTheme.titleMedium),
              ),
              const Icon(Icons.info_outline, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text('Unavailable — this data could not be loaded.',
              style: theme.textTheme.bodySmall),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.label, style: theme.textTheme.titleMedium),
              ),
              Text('${row.collected} / ${row.total}',
                  style: theme.textTheme.bodyMedium),
              if (page != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: row.fraction,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(_pct(row.fraction), style: theme.textTheme.bodySmall),
          if (category.note != null) ...[
            const SizedBox(height: 4),
            Text(category.note!, style: theme.textTheme.bodySmall),
          ],
          if (category.subgroups.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final sub in category.subgroups) _subgroupRow(context, sub),
          ],
        ],
      );
    }

    VoidCallback? onTap;
    if (page != null) {
      final target = page;
      onTap = () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => target),
          );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: body,
          ),
        ),
      ),
    );
  }

  /// A slice of a category (e.g. mementos from the Signature Store), with its
  /// own "Check all" — this is where bulk checking earns its keep, because the
  /// memento set alone is over a thousand items.
  Widget _subgroupRow(BuildContext context, CompletionCategory sub) {
    final theme = Theme.of(context);
    final collected = sub.collected(_store);
    final total = sub.total(_store);

    return Row(
      children: [
        Expanded(
          child: Text(
            sub.label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text('$collected / $total', style: theme.textTheme.bodySmall),
        CheckAllButton.multi(
          targets: <CheckAllTarget>[
            for (final p in sub.parts) CheckAllTarget(p.bucket, p.ids),
          ],
          groupLabel: sub.label,
        ),
      ],
    );
  }
}
