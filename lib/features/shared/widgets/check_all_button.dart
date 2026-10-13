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
///    real tracked progress,
///  * "Check all" is undoable: the ids that were already checked before the tap
///    are remembered, and the button offers to put the group back the way it
///    was rather than clearing progress the player entered by hand.
class CheckAllButton extends StatefulWidget {
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

  @override
  State<CheckAllButton> createState() => _CheckAllButtonState();

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
            'Nothing else you have tracked is affected, and you can tap Undo '
            'straight afterwards if you change your mind.',
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

  /// Shared confirmation for undoing a bulk check is deliberately absent:
  /// [_CheckAllButtonState._undoCheckAll] only takes back what the previous tap
  /// added, so there is nothing of the player's to lose.
}

class _CheckAllButtonState extends State<CheckAllButton> {
  final UnlockedStore _store = UnlockedStore.instance;

  /// What was checked in each bucket immediately before the last "Check all".
  ///
  /// Null when there is nothing to undo. Held per bucket because a group can
  /// span two (pet rooms + photo tasks).
  Map<String, Set<String>>? _restorePoint;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CheckAllButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page that swaps the group under the same button — the Courtyard page
    // changing tabs, say — must not offer to undo a check-all that happened on
    // a different set of ids.
    if (_restorePoint != null &&
        !_sameTargets(oldWidget.targets, widget.targets)) {
      _restorePoint = null;
    }
  }

  /// The undo is only valid while the group has stayed fully checked since the
  /// bulk tap. The moment the player unchecks anything by hand they are editing
  /// the group themselves, and "put it back how it was" no longer means
  /// anything they would recognise.
  void _onStoreChanged() {
    if (!mounted) return;
    if (_restorePoint != null && _checkedCount() != _totalIds) {
      setState(() => _restorePoint = null);
    } else {
      setState(() {});
    }
  }

  static bool _sameTargets(List<CheckAllTarget> a, List<CheckAllTarget> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].bucket != b[i].bucket) return false;
      final x = a[i].ids;
      final y = b[i].ids;
      if (x.length != y.length) return false;
      if (!identical(x, y)) {
        for (var j = 0; j < x.length; j++) {
          if (x[j] != y[j]) return false;
        }
      }
    }
    return true;
  }

  int get _totalIds {
    var n = 0;
    for (final t in widget.targets) {
      n += t.ids.length;
    }
    return n;
  }

  int _checkedCount() {
    var n = 0;
    for (final t in widget.targets) {
      for (final id in t.ids) {
        if (_store.isUnlocked(t.bucket, id)) n++;
      }
    }
    return n;
  }

  /// Whether undoing would actually preserve something.
  ///
  /// If nothing was checked before the bulk tap, undo and "uncheck all" do the
  /// same thing, and the plainer label is the honest one.
  bool get _canUndo {
    final restore = _restorePoint;
    if (restore == null) return false;
    return restore.values.any((ids) => ids.isNotEmpty);
  }

  Future<void> _checkAll() async {
    // Snapshot first: this is the state the undo goes back to.
    final restore = <String, Set<String>>{};
    for (final t in widget.targets) {
      restore[t.bucket] = <String>{
        for (final id in t.ids)
          if (_store.isUnlocked(t.bucket, id)) id,
      };
    }

    for (final t in widget.targets) {
      if (t.ids.isEmpty) continue;
      await _store.setManyUnlocked(t.bucket, t.ids, true);
    }

    if (mounted) setState(() => _restorePoint = restore);
    await _notify(true);
  }

  /// Puts the group back the way it was before the last "Check all".
  Future<void> _undoCheckAll() async {
    final restore = _restorePoint;
    if (restore == null) return;

    for (final t in widget.targets) {
      final keep = restore[t.bucket] ?? const <String>{};
      final clear = <String>[
        for (final id in t.ids)
          if (!keep.contains(id)) id,
      ];
      if (clear.isEmpty) continue;
      await _store.setManyUnlocked(t.bucket, clear, false);
    }

    if (mounted) setState(() => _restorePoint = null);
    await _notify(false);
  }

  Future<void> _uncheckAll(BuildContext context, int checked) async {
    if (checked > widget.confirmThreshold) {
      final ok = await CheckAllButton.confirmUncheck(
        context,
        count: checked,
        groupLabel: widget.groupLabel,
      );
      if (!ok) return;
    }

    for (final t in widget.targets) {
      if (t.ids.isEmpty) continue;
      await _store.setManyUnlocked(t.bucket, t.ids, false);
    }

    if (mounted) setState(() => _restorePoint = null);
    await _notify(false);
  }

  Future<void> _notify(bool value) async {
    final callback = widget.onApplied;
    if (callback != null) await callback(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_totalIds == 0) return const SizedBox.shrink();

    final checked = _checkedCount();
    final allChecked = checked == _totalIds;
    final canUndo = allChecked && _canUndo;

    return TextButton(
      onPressed: () async {
        if (!allChecked) {
          await _checkAll();
        } else if (canUndo) {
          await _undoCheckAll();
        } else {
          await _uncheckAll(context, checked);
        }
      },
      child: Text(
        !allChecked
            ? 'Check all'
            : canUndo
                ? 'Undo check all'
                : 'Uncheck all',
      ),
    );
  }
}
