import 'package:flutter/material.dart';

import '../../settings/data/feedback_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _feedbackCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _sendingFeedback = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
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
          ),

          const SizedBox(height: 10),

          // A Buy Me a Coffee card used to sit here. Guideline 3.1.1 treats an
          // in-app link to an outside payment mechanism as circumventing IAP,
          // and tip-jar link-outs have been rejected under it. Removed rather
          // than argued: the app is free with no ads either way, and a
          // rejection costs more than the tips would have.
          Text(
            'This app is free, has no ads and no in-app purchases.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
