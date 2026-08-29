import 'dart:async';

import 'package:flutter/material.dart';

import '../data/unlocked_store.dart';

/// One bucket + the ids inside it that a [CheckAllButton] toggles.
class CheckAllTarget {
  const CheckAllTarget(this.bucket, this.ids);

  /// UnlockedStore type key (e.g. 'dish', 'memento_collected').
  final String bucket;

  /// Every id in the group this button covers.
  final List<String> ids;
}

/// Shared "Check all" / "Uncheck all" control.
///
/// This is the same plain [TextButton] the hand-rolled versions on the
/// dishes / letters / customers / mementos pages already render, so it drops
/// into a header [Row] the same way. Differences from the hand-rolled ones:
///
///  * it always writes through [UnlockedStore.setManyUnlocked] (one persist +
///    one notify, never a loop of setUnlocked),
///  * it listens to the store itself, so the label stays correct even on pages
///    that do not wrap their body in an AnimatedBuilder,
///  * unchecking a large group asks for confirmation first, because that wipes
///    real tracked progress.
class CheckAllButton extends StatelessWidget {
  /// Single-bucket group (the common case).
  CheckAllButton({
    super.key,
    required String bucket,
    required List<String> ids,
    this.groupLabel,
    this.onApplied,
    this.confirmThreshold = 10,
  }) : targets = <CheckAllTarget>[CheckAllTarget(bucket, ids)];

  /// Group that spans more than one bucket (e.g. pet rooms + photo tasks).
  const CheckAllButton.multi({
    super.key,
    required this.targets,
    this.groupLabel,
    this.onApplied,
    this.confirmThreshold = 10,
  });

  final List<CheckAllTarget> targets;

  /// Name of the group, used in the confirmation dialog ("… in Letters").
  final String? groupLabel;

  /// Called with the value that was just applied (true = checked all), after
  /// the store has been updated. Use it to refresh a page's own setState-driven
  /// counters, or to keep dependent progress consistent.
  final FutureOr<void> Function(bool value)? onApplied;

  /// Unchecking more than this many already-checked items asks first.
  final int confirmThreshold;

  int get _totalIds {
    var n = 0;
    for (final t in targets) {
      n += t.ids.length;
    }
    return n;
  }

  int _checkedCount(UnlockedStore store) {
    var n = 0;
    for (final t in targets) {
      for (final id in t.ids) {
        if (store.isUnlocked(t.bucket, id)) n++;
      }
    }
    return n;
  }

  /// Shared confirmation for destructive bulk unchecks, in the app's existing
  /// dialog style (see SettingsPage's wipe dialog).
  static Future<bool> confirmUncheck(
    BuildContext context, {
    required int count,
    String? groupLabel,
  }) async {
    final label = (groupLabel ?? '').trim();
    final where = label.isEmpty ? '' : ' in $label';
    final noun = count == 1 ? 'item' : 'items';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Uncheck all?'),
          content: Text(
            'This clears $count checked $noun$where.\n\n'
            'Nothing else you have tracked is affected, but this cannot be '
            'undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, uncheck all'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _apply(BuildContext context, bool allChecked, int checked) async {
    final store = UnlockedStore.instance;
    final value = !allChecked;

    if (!value && checked > confirmThreshold) {
      final ok = await confirmUncheck(
        context,
        count: checked,
        groupLabel: groupLabel,
      );
      if (!ok) return;
    }

    for (final t in targets) {
      if (t.ids.isEmpty) continue;
      await store.setManyUnlocked(t.bucket, t.ids, value);
    }

    final callback = onApplied;
    if (callback != null) {
      await callback(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_totalIds == 0) return const SizedBox.shrink();

    final store = UnlockedStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final checked = _checkedCount(store);
        final allChecked = checked == _totalIds;

        return TextButton(
          onPressed: () => _apply(context, allChecked, checked),
          child: Text(allChecked ? 'Uncheck all' : 'Check all'),
        );
      },
    );
  }
}
