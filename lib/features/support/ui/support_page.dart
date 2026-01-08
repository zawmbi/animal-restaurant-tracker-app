import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../settings/data/feedback_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static final Uri _bmac = Uri.parse('https://buymeacoffee.com/zawmbi');

  final _feedbackCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _sendingFeedback = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _openBuyMeACoffee() async {
    final ok = await launchUrl(
      _bmac,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  Future<void> _submitFeedback() async {
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
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [


          const SizedBox(height:  12),

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
                  const SizedBox(height: 10),
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
                      onPressed: _sendingFeedback ? null : _submitFeedback,
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
          ),const SizedBox(height: 10),

        Card(
          child: ListTile(
            isThreeLine: true,
            title: Text(
              'Thank you for using this app! I develop independently and choose to keep it free with no ads. '
              'If you’d like to support development, you can do so here. Thank you <3',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 25),
              child: Text(
                'Support via BuyMeACoffee.com (External Link)',
                textAlign: TextAlign.center,
              ),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openBuyMeACoffee,
          ),
        ),

        ],
      ),
    );
  }
}
