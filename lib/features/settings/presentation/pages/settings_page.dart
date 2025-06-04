import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  // Settings state
  bool _highAccuracyLocation = true;
  bool _autoSync = false;
  bool _saveToGallery = false;
  bool _enableNotifications = true;
  bool _darkMode = false;
  double _imageQuality = 85.0;
  String _mapType = 'hybrid';
  int _cacheSize = 0;
  int _totalPoints = 0;
  int _syncedPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStatistics();
  }

  Future<void> _loadSettings() async {
    // Load settings from shared preferences or database
    // For now, using default values
    setState(() {
      // Settings would be loaded from storage here
    });
  }

  Future<void> _loadStatistics() async {
    try {
      final points = await _databaseService.getAllLandPoints();
      final stats = await _databaseService.getDatabaseStats();

      setState(() {
        _totalPoints = points.length;
        _syncedPoints = points.where((p) => p.isSynced).length;
        // Calculate cache size (approximate)
        _cacheSize = (points.length * 2.5).round(); // MB estimate
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return _buildSettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String Function(double) labelBuilder,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        _buildSettingsTile(
          title: title,
          subtitle: labelBuilder(value),
          icon: icon,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      final points = await _databaseService.getAllLandPoints();

      // Create CSV content
      StringBuffer csvContent = StringBuffer();
      csvContent.writeln(
          'ID,Latitude,Longitude,Timestamp,Land Feature,Vegetation %,Soil Type,Synced,Notes');

      for (final point in points) {
        csvContent.writeln([
          point.id,
          point.latitude,
          point.longitude,
          point.timestamp.toIso8601String(),
          point.analysis?.dominantLandFeature ?? '',
          point.analysis?.vegetationPercentage ?? '',
          point.analysis?.soilType ?? '',
          point.isSynced,
          point.notes ?? '',
        ].join(','));
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/land_mapping_data.csv');
      await file.writeAsString(csvContent.toString());

      Navigator.pop(context); // Close loading dialog

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Land Mapping Data Export',
        subject:
            'Land Points Data - ${DateTime.now().toString().split(' ')[0]}',
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'Are you sure you want to clear all cached data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Clear temporary files
                final tempDir = await getTemporaryDirectory();
                if (await tempDir.exists()) {
                  await tempDir.delete(recursive: true);
                }

                setState(() {
                  _cacheSize = 0;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error clearing cache: $e')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
            'This will delete ALL your data including photos and land points. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Resetting app...'),
                    ],
                  ),
                ),
              );

              try {
                // Clear database
                final points = await _databaseService.getAllLandPoints();
                for (final point in points) {
                  await _databaseService.deleteLandPoint(point.id);
                }

                // Clear cache
                final tempDir = await getTemporaryDirectory();
                if (await tempDir.exists()) {
                  await tempDir.delete(recursive: true);
                }

                Navigator.pop(context); // Close loading dialog

                await _loadStatistics();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App reset successfully')),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error resetting app: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Land Map',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.map, size: 48),
      children: [
        const Text(
            'AI-powered land mapping application using GPS and camera technology.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• GPS-based land point mapping'),
        const Text('• AI land feature analysis'),
        const Text('• Photo capture and storage'),
        const Text('• Data export and sharing'),
        const Text('• Offline functionality'),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use Land Map:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Take photos of land areas using the camera'),
            Text('2. GPS coordinates are automatically recorded'),
            Text('3. View all mapped points in the map section'),
            Text('4. Export data for analysis and sharing'),
            SizedBox(height: 16),
            Text('For support, contact: support@landmap.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStatistics();
          await _loadSettings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Section
              _buildSectionHeader('Statistics', Icons.analytics),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total Points', '$_totalPoints',
                        Icons.location_on, Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Synced', '$_syncedPoints', Icons.cloud_done,
                        Colors.green),
                    const SizedBox(width: 8),
                    _buildStatCard('Cache Size', '${_cacheSize}MB',
                        Icons.storage, Colors.orange),
                  ],
                ),
              ),

              // Location Settings
              _buildSectionHeader('Location', Icons.location_on),
              _buildSwitchTile(
                title: 'High Accuracy GPS',
                subtitle: 'Use precise location for better mapping',
                icon: Icons.gps_fixed,
                value: _highAccuracyLocation,
                onChanged: (value) =>
                    setState(() => _highAccuracyLocation = value),
              ),

              // Camera Settings
              _buildSectionHeader('Camera', Icons.camera_alt),
              _buildSwitchTile(
                title: 'Save to Gallery',
                subtitle: 'Also save photos to device gallery',
                icon: Icons.photo_library,
                value: _saveToGallery,
                onChanged: (value) => setState(() => _saveToGallery = value),
              ),
              _buildSliderTile(
                title: 'Image Quality',
                icon: Icons.photo_camera,
                value: _imageQuality,
                min: 50,
                max: 100,
                labelBuilder: (value) => '${value.round()}% quality',
                onChanged: (value) => setState(() => _imageQuality = value),
              ),

              // Sync & Data
              _buildSectionHeader('Data & Sync', Icons.sync),
              _buildSwitchTile(
                title: 'Auto Sync',
                subtitle: 'Automatically sync data when connected',
                icon: Icons.cloud_sync,
                value: _autoSync,
                onChanged: (value) => setState(() => _autoSync = value),
              ),
              _buildSettingsTile(
                title: 'Export Data',
                subtitle: 'Export all land points to CSV',
                icon: Icons.download,
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportData,
              ),

              // App Settings
              _buildSectionHeader('App Settings', Icons.settings),
              _buildSwitchTile(
                title: 'Notifications',
                subtitle: 'Enable app notifications',
                icon: Icons.notifications,
                value: _enableNotifications,
                onChanged: (value) =>
                    setState(() => _enableNotifications = value),
              ),
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                icon: Icons.dark_mode,
                value: _darkMode,
                onChanged: (value) => setState(() => _darkMode = value),
              ),

              // Storage & Cache
              _buildSectionHeader('Storage', Icons.storage),
              _buildSettingsTile(
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                icon: Icons.cleaning_services,
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearCache,
              ),
              _buildSettingsTile(
                title: 'Reset App',
                subtitle: 'Delete all data and reset settings',
                icon: Icons.restore,
                iconColor: Colors.red,
                trailing: const Icon(Icons.chevron_right),
                onTap: _resetApp,
              ),

              // About & Support
              _buildSectionHeader('About & Support', Icons.info),
              _buildSettingsTile(
                title: 'Help & FAQ',
                subtitle: 'Get help and support',
                icon: Icons.help,
                trailing: const Icon(Icons.chevron_right),
                onTap: _showHelp,
              ),
              _buildSettingsTile(
                title: 'About Land Map',
                subtitle: 'Version 1.0.0',
                icon: Icons.info_outline,
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAbout,
              ),

              // Version info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Land Map v1.0.0\nBuilt with Flutter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
