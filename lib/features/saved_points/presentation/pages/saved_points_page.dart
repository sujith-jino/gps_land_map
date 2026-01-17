import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';

class SavedPointsPage extends StatefulWidget {
  const SavedPointsPage({super.key});

  @override
  State<SavedPointsPage> createState() => _SavedPointsPageState();
}

class _SavedPointsPageState extends State<SavedPointsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<LandPoint> _allPoints = [];
  List<LandPoint> _filteredPoints = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // 'date', 'name', 'location'
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPoints();
    _searchController.addListener(_filterPoints);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPoints() async {
    try {
      setState(() => _isLoading = true);

      final points = await _databaseService.getAllLandPoints();

      setState(() {
        _allPoints = points;
        _filteredPoints = points;
        _isLoading = false;
      });

      _sortPoints();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingSavedPoints}: $e'),
          ),
        );
      }
    }
  }

  void _filterPoints() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredPoints = List.from(_allPoints);
      } else {
        _filteredPoints = _allPoints.where((point) {
          final notesMatch = point.notes?.toLowerCase().contains(query) ??
              false;
          final landFeatureMatch = point.analysis?.dominantLandFeature
              .toLowerCase().contains(query) ?? false;
          final soilTypeMatch = point.analysis?.soilType.toLowerCase().contains(
              query) ?? false;

          return notesMatch || landFeatureMatch || soilTypeMatch;
        }).toList();
      }
    });

    _sortPoints();
  }

  void _sortPoints() {
    setState(() {
      _filteredPoints.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case 'date':
            comparison = a.timestamp.compareTo(b.timestamp);
            break;
          case 'location':
            comparison = a.latitude.compareTo(b.latitude);
            break;
          case 'name':
            final l10n = AppLocalizations.of(context)!;
            final aName = a.notes ?? l10n.unnamedPoint;
            final bName = b.notes ?? l10n.unnamedPoint;
            comparison = aName.compareTo(bName);
            break;
        }

        return _isAscending ? comparison : -comparison;
      });
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sortBy,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(l10n.date),
                trailing: _sortBy == 'date' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'date');
                  _sortPoints();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(l10n.location),
                trailing:
                    _sortBy == 'location' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'location');
                  _sortPoints();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: Text(l10n.name),
                trailing: _sortBy == 'name' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'name');
                  _sortPoints();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                title: Text(_isAscending ? l10n.ascending : l10n.descending),
                onTap: () {
                  setState(() => _isAscending = !_isAscending);
                  _sortPoints();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPointDetails(LandPoint point) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(point.notes ?? l10n.unnamedPoint),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(l10n.latitude, point.latitude.toStringAsFixed(6)),
              _buildDetailRow(
                  l10n.longitude, point.longitude.toStringAsFixed(6)),
              _buildDetailRow(l10n.date, _formatDate(point.timestamp)),
              if (point.analysis != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.analysisResults,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                    l10n.landFeature, point.analysis!.dominantLandFeature),
                _buildDetailRow(l10n.soilType, point.analysis!.soilType),
                _buildDetailRow(l10n.vegetationCoverage,
                    '${point.analysis!.vegetationPercentage.toStringAsFixed(1)}%'),
                _buildDetailRow(l10n.waterCoverage,
                    '${point.analysis!.waterBodyPercentage.toStringAsFixed(1)}%'),
                _buildDetailRow(l10n.elevationEstimate,
                    '${point.analysis!.elevationEstimate.toStringAsFixed(1)}m'),
                _buildDetailRow(l10n.confidence,
                    '${point.analysis!.confidenceScore.toStringAsFixed(1)}%'),
              ],
              if (point.notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.notes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(point.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePoint(point);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute
        .toString().padLeft(2, '0')}';
  }

  Future<void> _deletePoint(LandPoint point) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePoint),
        content: Text(l10n.areYouSureDeletePoint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteLandPoint(point.id);
        await _loadSavedPoints();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pointDeletedSuccessfully),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorDeletingPoint}: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                l10n?.savedPoints ?? 'Saved Points',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortOptions,
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n?.searchSavedPoints ?? 'Search saved points...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Points List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPoints.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadSavedPoints,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPoints.length,
                        itemBuilder: (context, index) {
                          final point = _filteredPoints[index];
                          return _buildPointCard(point);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? l10n.noPointsFound
                : l10n.noSavedPointsYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? l10n.tryAdjustingSearch
                : l10n.startCapturingPoints,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(LandPoint point) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          point.notes ?? l10n.unnamedPoint,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(point.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (point.analysis != null) ...[
              const SizedBox(height: 4),
              Text(
                point.analysis!.dominantLandFeature,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showPointDetails(point),
      ),
    );
  }
}
