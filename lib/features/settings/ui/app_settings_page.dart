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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light'),
                        subtitle: const Text('Always use light mode'),
                        value: ThemeMode.light,
                        groupValue: settings.themeMode,
                        onChanged: (mode) {
                          if (mode != null) {
                            settings.setThemeMode(mode);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark'),
                        subtitle: const Text('Always use dark mode'),
                        value: ThemeMode.dark,
                        groupValue: settings.themeMode,
                        onChanged: (mode) {
                          if (mode != null) {
                            settings.setThemeMode(mode);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('System'),
                        subtitle: const Text('Follow device settings'),
                        value: ThemeMode.system,
                        groupValue: settings.themeMode,
                        onChanged: (mode) {
                          if (mode != null) {
                            settings.setThemeMode(mode);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
