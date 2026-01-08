import 'package:flutter/material.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(
                'Dark mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Coming soon.'),
              ),
              trailing: Switch(
                value: false,
                onChanged: null, // not wired yet
              ),
            ),
          ),
        ],
      ),
    );
  }
}
