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
    }
    finally {
      if (mounted) {
        setState(() => _sendingFeedback = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Feedback / Contact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Have feedback, concerns, or ideas? Fill this out and it will be '
                    'sent through the app.',
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

          // Danger zone
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
