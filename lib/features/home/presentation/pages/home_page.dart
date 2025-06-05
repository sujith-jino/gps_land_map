import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/navigation/app_router.dart';
import '../widgets/home_stats_card.dart';
import '../widgets/recent_points_list.dart';
import '../widgets/quick_actions_grid.dart';
import '../../../../simple_map_test.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  List<LandPoint> _recentPoints = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    // Check location permission on app start
    final hasLocationPermission =
        await _locationService.requestLocationPermission();

    if (!hasLocationPermission && mounted) {
      // Check if it's just location services disabled or permission denied
      final permission = await _locationService.checkLocationPermission();
      final servicesEnabled = await _locationService.isLocationServiceEnabled();

      String message;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        message = 'Location permission required for better experience';
      } else if (!servicesEnabled) {
        message = 'Please enable location services in device settings';
      } else {
        message = 'Location access needed for full functionality';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () async {
              await _locationService.requestLocationPermission();
            },
          ),
        ),
      );
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final allPoints = await _databaseService.getAllLandPoints();
      final stats = await _databaseService.getDatabaseStats();

      // Get recent points (last 10)
      allPoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final recentPoints = allPoints.take(10).toList();

      setState(() {
        _recentPoints = recentPoints;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppRouter.navigateToSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  // Space for bottom nav bar
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Welcome Section
                      _buildWelcomeSection(l10n),
                      const SizedBox(height: 20),

                      // Quick Actions
                      _buildSectionTitle(l10n.home, Icons.home),
                      const SizedBox(height: 12),
                      QuickActionsGrid(onActionTap: _handleQuickAction),
                      const SizedBox(height: 20),

                      // Statistics
                      if (_stats != null) ...[
                        _buildSectionTitle('Statistics', Icons.analytics),
                        const SizedBox(height: 12),
                        HomeStatsCard(stats: _stats!),
                        const SizedBox(height: 20),
                      ],

                      // Recent Points
                      _buildSectionTitle(l10n.savedPoints, Icons.location_on),
                      const SizedBox(height: 12),
                      RecentPointsList(
                        points: _recentPoints,
                        onPointTap: _handlePointTap,
                      ),

                        // Test Buttons
                        const SizedBox(height: 20),
                        _buildSectionTitle('API Tests', Icons.bug_report),
                        const SizedBox(height: 12),

                        // Google Maps Test Button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SimpleMapTest()),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.map_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Test Google Maps API',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Direct API Key verification test',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ),
                ),
              ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(l10n),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF66BB6A),
            Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Land Mapper',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered precision mapping',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStat(
                  icon: Icons.location_on,
                  value: '${_stats?['totalPoints'] ?? 0}',
                  label: 'Land Points',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardStat(
                  icon: Icons.area_chart,
                  value:
                      '${(_stats?['totalArea'] ?? 0).toStringAsFixed(1)} km²',
                  label: 'Area Mapped',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStat(
                  icon: Icons.sync,
                  value: '${_stats?['syncedPoints'] ?? 0}',
                  label: 'Synced',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardStat(
                  icon: Icons.pending,
                  value: '${_stats?['unsyncedPoints'] ?? 0}',
                  label: 'Pending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme
            .of(context)
            .primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme
              .of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(AppLocalizations l10n) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home Button
          _buildBottomNavButton(
            icon: Icons.home_rounded,
            label: l10n.home,
            isSelected: true,
            onTap: () {},
          ),

          // Map Button
          _buildBottomNavButton(
            icon: Icons.map_rounded,
            label: l10n.map,
            onTap: () => AppRouter.navigateToMap(context),
          ),

          // Camera Button (Center)
          GestureDetector(
            onTap: () => AppRouter.navigateToCamera(context),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Points Button
          _buildBottomNavButton(
            icon: Icons.location_on_rounded,
            label: l10n.savedPoints,
            onTap: () => AppRouter.navigateToSavedPoints(context),
          ),

          // Settings Button
          _buildBottomNavButton(
            icon: Icons.settings_rounded,
            label: l10n.settings,
            onTap: () => AppRouter.navigateToSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'camera':
        AppRouter.navigateToCamera(context);
        break;
      case 'map':
        AppRouter.navigateToMap(context);
        break;
      case 'location':
        _getCurrentLocation();
        break;
      case 'sync':
        _syncData();
        break;
    }
  }

  void _handlePointTap(LandPoint point) {
    // Navigate to point details
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Land Point Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitude: ${point.latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${point.longitude.toStringAsFixed(6)}'),
                if (point.analysis != null) ...[
                  const SizedBox(height: 8),
                  Text('Land Feature: ${point.analysis!.dominantLandFeature}'),
                  Text('Soil Type: ${point.analysis!.soilType}'),
                  Text('Vegetation: ${point.analysis!.vegetationPercentage
                      .toStringAsFixed(1)}%'),
                ],
                if (point.notes != null) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${point.notes}'),
                ],
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

  void _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'MAP',
              textColor: Colors.white,
              onPressed: () => AppRouter.navigateToMap(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error getting location: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data...')),
    );
    // Implement sync logic
  }
}
