import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/navigation/app_router.dart';
import '../widgets/home_stats_card.dart';
import '../widgets/recent_points_list.dart';
import '../widgets/quick_actions_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService();
  List<LandPoint> _recentPoints = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
                  padding: const EdgeInsets.only(bottom: 76), // Space for bottom nav bar
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 8.0),
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
                    ],
                  ),
                ),
              ),
        ),
      ),
      floatingActionButton: null,
      bottomNavigationBar: _buildBottomNavigationBar(l10n),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.landMapping,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to AI-powered land mapping',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildStatItem(
                icon: Icons.location_on,
                value: '${_stats?['totalPoints'] ?? 0}',
                label: 'Points Mapped',
              ),
              _buildStatItem(
                icon: Icons.sync,
                value: '${_stats?['unsyncedPoints'] ?? 0}',
                label: 'Unsynced',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Height constant for the bottom navigation bar
  static const double _bottomNavBarHeight = 64.0;

  Widget _buildBottomNavigationBar(AppLocalizations l10n) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Container(
        height: _bottomNavBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home Button
            _buildBottomNavButton(
              icon: Icons.home,
              label: l10n.home,
              isSelected: true,
              onTap: () {},
            ),
            
            // Map Button
            _buildBottomNavButton(
              icon: Icons.map,
              label: l10n.map,
              onTap: () => AppRouter.navigateToMap(context),
            ),

            // Camera Button
            _buildBottomNavButton(
              icon: Icons.camera_alt,
              label: l10n.camera,
              onTap: () => AppRouter.navigateToCamera(context),
            ),

            // Saved Points Button
            _buildBottomNavButton(
              icon: Icons.bookmark,
              label: l10n.savedPoints,
              onTap: () => _navigateToSavedPoints(),
            ),

            // Settings Button
            _buildBottomNavButton(
              icon: Icons.settings,
              label: l10n.settings,
              onTap: () => AppRouter.navigateToSettings(context),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              const SizedBox(height: 2),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
      case 'measure':
        AppRouter.navigateToLandMeasure(context);
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

  void _getCurrentLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting current location...')),
    );
    // Implement location getting logic
  }

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data...')),
    );
    // Implement sync logic
  }

  void _navigateToSavedPoints() {
    // Implement navigation to saved points
  }
}
