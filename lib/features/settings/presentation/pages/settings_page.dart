import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Theme Settings
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(themeProvider.themeModeName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, themeProvider),
          ),

          // Dark Mode Toggle
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleDarkMode(value);
            },
          ),

          // About Section
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Land Map v1.0.0'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context,
      ThemeProvider themeProvider) async {
    final selectedTheme = await showDialog<String>(
      context: context,
      builder: (context) =>
          SimpleDialog(
            title: const Text('Select Theme'),
            children: [
              RadioListTile<String>(
                title: const Text('System'),
                value: 'System',
                groupValue: themeProvider.themeModeName,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
                title: const Text('Light'),
                value: 'Light',
                groupValue: themeProvider.themeModeName,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
                title: const Text('Dark'),
                value: 'Dark',
                groupValue: themeProvider.themeModeName,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
    );

    if (selectedTheme != null) {
      switch (selectedTheme) {
        case 'System':
          themeProvider.setThemeMode(ThemeMode.system);
          break;
        case 'Light':
          themeProvider.setThemeMode(ThemeMode.light);
          break;
        case 'Dark':
          themeProvider.setThemeMode(ThemeMode.dark);
          break;
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Land Map',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.map, size: 48),
      children: const [
        Text(
            'AI-powered land mapping application using GPS and camera technology.'),
      ],
    );
  }
}