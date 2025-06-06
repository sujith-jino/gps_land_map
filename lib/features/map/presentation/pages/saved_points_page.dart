import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedPoint {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? notes;

  SavedPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.notes,
  });
}

class SavedPointsPage extends StatefulWidget {
  const SavedPointsPage({super.key});

  @override
  State<SavedPointsPage> createState() => _SavedPointsPageState();
}

class _SavedPointsPageState extends State<SavedPointsPage> {
  List<SavedPoint> _savedPoints = [];

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToMap(SavedPoint point) {
    Navigator.pop(context, point);
  }

  void _deletePoint(SavedPoint point) {
    setState(() {
      _savedPoints.removeWhere((p) => p.id == point.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Point deleted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDeletePoint(SavedPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Point'),
        content: const Text('Are you sure you want to delete this point?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePoint(point);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Points'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _savedPoints.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved points yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedPoints.length,
              itemBuilder: (context, index) {
                final point = _savedPoints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Point ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        Text('${_formatDate(point.timestamp)} ${_formatTime(point.timestamp)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () => _navigateToMap(point),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeletePoint(point),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
