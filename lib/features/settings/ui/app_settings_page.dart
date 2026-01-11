import 'package:flutter/material.dart';
import '../data/app_settings_controller.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('App Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: Text(
                    'Dark mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Use a darker color scheme.'),
                  ),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    // If you want a pure on/off toggle:
                    // ON -> dark, OFF -> light
                    settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),

              // Optional: if you want System / Light / Dark instead of a switch,
              // tell me and I’ll swap this UI to a segmented control / radios.
            ],
          ),
        );
      },
    );
  }
}
