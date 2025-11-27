import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animal_restaurant_tracker/features/timers/data/timer_service.dart';

class TimersPage extends StatefulWidget {
  const TimersPage({super.key});

  @override
  State<TimersPage> createState() => _TimersPageState();
}

class _TimersPageState extends State<TimersPage> {
  final List<_ActiveTimer> _active = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_active.isNotEmpty) _activeTimersCard(context),
          _buffetTipJarCard(context),
          const SizedBox(height: 12),
          _takeoutCard(context),
          const SizedBox(height: 12),
          _performersCard(context),
          const SizedBox(height: 12),
          _generalTimerCard(context),
        ],
      ),
    );
  }

  // ---------- Active countdowns ----------

  Widget _activeTimersCard(BuildContext context) {
    final now = DateTime.now();
    _active.removeWhere((t) => t.target.isBefore(now));

    if (_active.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_bottom),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Timers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await TimerService.instance.cancelAll();
                    setState(() => _active.clear());
                  },
                  child: const Text('Cancel all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._active.map((t) {
              final remaining = t.target.difference(now);
              final hours = remaining.inHours;
              final minutes = remaining.inMinutes % 60;
              final seconds = remaining.inSeconds % 60;
              final formatted =
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.label),
                subtitle: Text('Ends at ${_formatTime(t.target)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Cancel',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await TimerService.instance.cancelTimer(t.id);
                        setState(() {
                          _active.removeWhere((x) => x.id == t.id);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------- Buffet / Tip Jar ----------

  Widget _buffetTipJarCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                Text(
                  'Buffet and Tip Jar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quick 12-hour timers for your buffet and tip jar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _setTimer(
                    context,
                    label: 'Buffet (12h)',
                    id: 'buffet_12h',
                    title: 'Buffet ready',
                    body: 'Your buffet timer has finished.',
                    duration: const Duration(hours: 12),
                    enforceSingle: true,
                  ),
                  child: const Text('Buffet 12h'),
                ),
                FilledButton(
                  onPressed: () => _setTimer(
                    context,
                    label: 'Tip Jar (12h)',
                    id: 'tipjar_12h',
                    title: 'Tip Jar ready',
                    body: 'Your tip jar timer has finished.',
                    duration: const Duration(hours: 12),
                    enforceSingle: true,
                  ),
                  child: const Text('Tip Jar 12h'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Takeout ----------

  Widget _takeoutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.takeout_dining),
                const SizedBox(width: 8),
                Text(
                  'Takeout',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set timers for Delivery Boy Tate and Delivery Girl Kate. '
              'Choose hours and minutes (up to 12 hours).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _takeoutButton(
              context,
              label: 'Takeout 1 (Delivery Boy Tate)',
              idBase: 'takeout1',
            ),
            const SizedBox(height: 8),
            _takeoutButton(
              context,
              label: 'Takeout 2 (Delivery Girl Kate)',
              idBase: 'takeout2',
            ),
          ],
        ),
      ),
    );
  }

  Widget _takeoutButton(
    BuildContext context, {
    required String label,
    required String idBase,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        FilledButton.tonal(
          onPressed: () async {
            final duration = await _pickDuration(
              context: context,
              maxHours: 12,
              maxTotalMinutes: 12 * 60,
              initialHours: 2,
              initialMinutes: 0,
              title: label,
            );
            if (duration == null) return;

            // One of each Takeout timer: id only depends on which slot (1 or 2)
            final id = idBase;

            await _setTimer(
              context,
              label: label,
              id: id,
              title: '$label ready',
              body: 'Your takeout timer has finished.',
              duration: duration,
              enforceSingle: true,
            );
          },
          child: const Text('Set'),
        ),
      ],
    );
  }

  // ---------- Performers ----------

  Widget _performersCard(BuildContext context) {
    const performers = [
      'Performer 1',
      'Performer 2',
      'Performer 3',
      'Performer 4',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 8),
                Text(
                  'Performers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Each performer can have a timer of up to 1 hour. '
              'You can choose minutes as well.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Column(
              children: performers.map((name) {
                final id = 'performer_$name';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(name)),
                      FilledButton.tonal(
                        onPressed: () async {
                          final duration = await _pickDuration(
                            context: context,
                            maxHours: 1,
                            maxTotalMinutes: 60,
                            initialHours: 0,
                            initialMinutes: 30,
                            title: name,
                          );
                          if (duration == null) return;

                          await _setTimer(
                            context,
                            label: name,
                            id: id,
                            title: '$name ready',
                            body: 'Your performer timer has finished.',
                            duration: duration,
                            enforceSingle: true,
                          );
                        },
                        child: const Text('Set'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- General Timer ----------

  Widget _generalTimerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text(
                  'General Timer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set a general timer for as much time as you want, for any purpose you wish. You can even rename it! '
              'There is no 12-hour limit here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final label =
                      await _askGeneralTimerLabel(context) ?? 'General timer';
                  if (!mounted) return;

                  final duration = await _pickDuration(
                    context: context,
                    maxHours: 99,
                    maxTotalMinutes: null,
                    initialHours: 1,
                    initialMinutes: 0,
                    title: label,
                  );
                  if (duration == null) return;

                  // General timers can be many; make id unique with timestamp
                  final sanitized = label.trim().isEmpty
                      ? 'general'
                      : label.trim().toLowerCase();
                  final safeName = sanitized
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                      .replaceAll(RegExp(r'_+'), '_')
                      .replaceAll(RegExp(r'^_+|_+$'), '');
                  final id =
                      'general_${safeName}_${DateTime.now().millisecondsSinceEpoch}';

                  await _setTimer(
                    context,
                    label: label,
                    id: id,
                    title: '$label finished',
                    body: 'Your "$label" timer has finished.',
                    duration: duration,
                    enforceSingle: false, // allow many general timers
                  );
                },
                child: const Text('Set general timer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  Future<void> _setTimer(
    BuildContext context, {
    required String label,
    required String id,
    required String title,
    required String body,
    required Duration duration,
    required bool enforceSingle,
  }) async {
    // If this type enforces only one active timer, block duplicates
    if (enforceSingle && _active.any((t) => t.id == id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oops! You can only set one of each timer.'),
        ),
      );
      return;
    }

    await TimerService.instance
        .scheduleTimer(id: id, title: title, body: body, duration: duration);

    final target = DateTime.now().add(duration);
    _active.add(_ActiveTimer(id: id, label: label, target: target));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Timer set for ${_fmtDuration(duration)}')),
    );
    setState(() {});
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<String?> _askGeneralTimerLabel(BuildContext context) async {
    final controller = TextEditingController(text: 'General timer');
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Name this timer'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Timer name',
              hintText: 'e.g. Event, Cleaning, Reminder',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.of(ctx).pop(
                  text.isEmpty ? 'General timer' : text,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<Duration?> _pickDuration({
    required BuildContext context,
    required int maxHours,
    required int? maxTotalMinutes,
    required int initialHours,
    required int initialMinutes,
    required String title,
  }) async {
    int selectedHours = initialHours.clamp(0, maxHours);
    int selectedMinutes = initialMinutes.clamp(0, 59);

    return showModalBottomSheet<Duration>(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        var totalMinutes =
                            selectedHours * 60 + selectedMinutes;
                        if (maxTotalMinutes != null &&
                            totalMinutes > maxTotalMinutes) {
                          totalMinutes = maxTotalMinutes;
                        }
                        if (totalMinutes <= 0) {
                          Navigator.of(ctx).pop();
                          return;
                        }
                        Navigator.of(ctx)
                            .pop(Duration(minutes: totalMinutes));
                      },
                      child: const Text('Set'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedHours,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (v) {
                          selectedHours = v;
                        },
                        children: List.generate(
                          maxHours + 1,
                          (i) => Center(child: Text('$i h')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMinutes,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (v) {
                          selectedMinutes = v;
                        },
                        children: List.generate(
                          60,
                          (i) => Center(child: Text('$i m')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveTimer {
  final String id;
  final String label;
  final DateTime target;

  _ActiveTimer({
    required this.id,
    required this.label,
    required this.target,
  });
}
