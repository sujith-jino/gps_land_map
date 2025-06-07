import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../shared/theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        // App Bar replacement
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                l10n.settings,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Settings List
        Expanded(
          child: ListView(
            children: [
              // Language Settings
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(languageProvider.currentLanguageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showLanguageDialog(context, languageProvider, l10n),
              ),

              const Divider(),

              // Theme Settings
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.theme),
                subtitle: Text(themeProvider.themeModeName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider, l10n),
              ),

              // Dark Mode Toggle
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: Text(l10n.darkMode),
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
                title: Text(l10n.about),
                subtitle: const Text('Land Map v1.0.0'),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageDialog(BuildContext context,
      LanguageProvider languageProvider, AppLocalizations l10n) async {
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LanguageProvider.languageOrder.map((languageCode) {
              final languageName =
                  LanguageProvider.languageNames[languageCode]!;
              return RadioListTile<String>(
                title: Text(
                  languageName,
                  style: const TextStyle(fontSize: 16),
                ),
                value: languageCode,
                groupValue: languageProvider.currentLocale.languageCode,
                onChanged: (value) => Navigator.pop(context, value),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedLanguage != null &&
        selectedLanguage != languageProvider.currentLocale.languageCode) {
      await languageProvider.changeLanguage(selectedLanguage);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.languageChanged),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showThemeDialog(BuildContext context,
      ThemeProvider themeProvider, AppLocalizations l10n) async {
    final selectedTheme = await showDialog<String>(
      context: context,
      builder: (context) =>
          SimpleDialog(
        title: Text(l10n.selectTheme),
        children: [
              RadioListTile<String>(
            title: Text(l10n.system),
            value: 'System',
                groupValue: themeProvider.themeModeName,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
            title: Text(l10n.light),
            value: 'Light',
                groupValue: themeProvider.themeModeName,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
            title: Text(l10n.dark),
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
