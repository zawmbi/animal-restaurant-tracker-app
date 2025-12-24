import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';
import 'package:animal_restaurant_tracker/features/timers/data/timer_service.dart';
import 'package:animal_restaurant_tracker/features/settings/data/feedback_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _feedbackCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _sendingFeedback = false;

  late final SyncedVersionsData _syncedVersions;

  // Edit this JSON whenever you want (no other code changes needed).
  // You can set statuses to: "Synced", "Not Fully Synced", "Upcoming Update"
  static const String _syncedVersionsJson = '''
{
  "syncedUpTo": "v11.10.0.g",
  "latestVersion": "v11.10.0.g",
  "latestSynced": true,
  "upcoming": {
    "provided": false,
    "version": "v11.11.0"
  },
  "rows": [
    { "area": "Base game content", "version": "v11.10.0.g", "status": "Synced" },
    { "area": "Event content", "version": "v11.10.0.g", "status": "Not Synced" },
    { "area": "Next update", "version": "v11.11.0", "status": "Upcoming" }
  ]
}
''';

  @override
  void initState() {
    super.initState();
    _syncedVersions = SyncedVersionsData.fromJson(
      jsonDecode(_syncedVersionsJson) as Map<String, dynamic>,
    );
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndWipe(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Wipe all data?'),
          content: const Text(
            'This will reset all your saved progress in this app, including '
            'unlocked customers, facilities, mementos, and timers.\n\n'
            'This cannot be undone. Are you sure you want to continue?',
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
              child: const Text('Yes, wipe everything'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await UnlockedStore.instance.clearAll();
    await TimerService.instance.cancelAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been wiped.')),
    );
  }

  Future<void> _submitFeedback(BuildContext context) async {
    final msg = _feedbackCtrl.text.trim();
    final contact = _contactCtrl.text.trim();

    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some feedback first.')),
      );
      return;
    }

    setState(() => _sendingFeedback = true);
    try {
      await FeedbackService.instance.sendFeedback(
        message: msg,
        contact: contact.isEmpty ? null : contact,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent. Thank you.')),
      );

      _feedbackCtrl.clear();
      _contactCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingFeedback = false);
      }
    }
  }

  void _openSyncedVersions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SyncedVersionsPage(data: _syncedVersions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestLine = _syncedVersions.latestSynced
        ? 'Latest version synced'
        : 'Not fully synced to latest';
    final upcomingLine = _syncedVersions.upcomingProvided
        ? 'Upcoming update: ${_syncedVersions.upcomingVersion ?? "Yes"}'
        : 'Upcoming update: No';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic info

          const SizedBox(height: 16),

          // Feedback (stays in this page, no redirection)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback / Report Bugs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Have feedback, concerns, or ideas? Fill this form out and it will be '
                    'sent through the app. We will get back to you as soon as possible.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feedbackCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Feedback / concerns',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact info (optional)',
                      hintText: 'Email, Discord, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed:
                          _sendingFeedback ? null : () => _submitFeedback(context),
                      child: _sendingFeedback
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send feedback'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          //  Synced Versions (second-to-last section)
          Card(
            child: ListTile(
              title: Text(
                'Synced Versions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Updated through: ${_syncedVersions.syncedUpTo}\n'
                  '$latestLine • $upcomingLine',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openSyncedVersions,
            ),
          ),

          const SizedBox(height: 16),

          // Danger zone (keep at bottom)
          Card(
            color: Colors.red.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger zone',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wipe all saved data for this app. This will clear all unlocks and '
                    'scheduled timers. This action cannot be undone.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _confirmAndWipe(context),
                      child: const Text('Wipe all data'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SyncedVersionsPage extends StatelessWidget {
  const SyncedVersionsPage({super.key, required this.data});

  final SyncedVersionsData data;

  @override
  Widget build(BuildContext context) {
    final latestLine =
        data.latestSynced ? 'Synced' : 'Not Fully Synced';
    final upcomingLine = data.upcomingProvided
        ? (data.upcomingVersion == null || data.upcomingVersion!.trim().isEmpty
            ? 'Yes'
            : data.upcomingVersion!)
        : 'No';

    return Scaffold(
      appBar: AppBar(title: const Text('Synced Versions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Updated through game version: ${data.syncedUpTo}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Latest version: ${data.latestVersion} ($latestLine)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upcoming update provided: $upcomingLine',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Keep this from becoming a giant screen-tall table
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Section')),
                            DataColumn(label: Text('Version')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: data.rows
                              .map(
                                (r) => DataRow(
                                  cells: [
                                    DataCell(Text(r.area)),
                                    DataCell(Text(r.version)),
                                    DataCell(Text(r.status)),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SyncedVersionsData {
  SyncedVersionsData({
    required this.syncedUpTo,
    required this.latestVersion,
    required this.latestSynced,
    required this.upcomingProvided,
    required this.upcomingVersion,
    required this.rows,
  });

  final String syncedUpTo;
  final String latestVersion;
  final bool latestSynced;
  final bool upcomingProvided;
  final String? upcomingVersion;
  final List<SyncedVersionRow> rows;

  factory SyncedVersionsData.fromJson(Map<String, dynamic> json) {
    final upcoming = (json['upcoming'] as Map?)?.cast<String, dynamic>() ?? {};
    final rowsRaw = (json['rows'] as List?) ?? const [];

    return SyncedVersionsData(
      syncedUpTo: (json['syncedUpTo'] ?? '').toString(),
      latestVersion: (json['latestVersion'] ?? '').toString(),
      latestSynced: (json['latestSynced'] as bool?) ?? false,
      upcomingProvided: (upcoming['provided'] as bool?) ?? false,
      upcomingVersion: upcoming['version']?.toString(),
      rows: rowsRaw
          .whereType<Map>()
          .map((m) => SyncedVersionRow.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class SyncedVersionRow {
  SyncedVersionRow({
    required this.area,
    required this.version,
    required this.status,
  });

  final String area;
  final String version;
  final String status;

  factory SyncedVersionRow.fromJson(Map<String, dynamic> json) {
    return SyncedVersionRow(
      area: (json['area'] ?? '').toString(),
      version: (json['version'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}
