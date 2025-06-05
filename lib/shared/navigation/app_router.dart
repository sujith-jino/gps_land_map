import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';


class AppRouter {
  static const String home = '/';
  static const String camera = '/camera';
  static const String map = '/map';
  static const String testMap = '/test-map';
  static const String settings = '/settings';
  static const String landPointDetails = '/land-point-details';
  static const String imageAnalysis = '/image-analysis';

  /// Generate routes based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case '/camera':
        return MaterialPageRoute(
          builder: (_) => const CameraPage(),
        );
      case '/map':
        return MaterialPageRoute(
          builder: (_) => const MapPage(),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        );
      case '/land-point-details':
        final landPointId = settings.arguments as String?;
        // TODO: Replace with actual LandPointDetailsPage
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Land Point Details')),
            body: Center(child: Text('Details for land point: $landPointId')),
          ),
        );
      case '/image-analysis':
        final imagePath = settings.arguments as String?;
        // TODO: Replace with actual ImageAnalysisPage
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Image Analysis')),
            body: Center(child: Image.asset(imagePath ?? '')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
          const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }

  /// Navigate to the camera page
  static Future<void> navigateToCamera(BuildContext context) async {
    await Navigator.pushNamed(context, camera);
  }

  /// Navigate to the map page
  static Future<void> navigateToMap(BuildContext context) async {
    await Navigator.pushNamed(context, map);
  }

  /// Navigate to the test map page
  static Future<void> navigateToTestMap(BuildContext context) async {
    await Navigator.pushNamed(context, testMap);
  }

  /// Navigate to the settings page
  static Future<void> navigateToSettings(BuildContext context) async {
    await Navigator.pushNamed(context, settings);
  }

  /// Navigate to land point details page
  static Future<void> navigateToLandPointDetails(
    BuildContext context, {
    required String landPointId,
  }) async {
    await Navigator.pushNamed(
      context, 
      landPointDetails,
      arguments: landPointId,
    );
  }

  /// Navigate to image analysis page
  static Future<void> navigateToImageAnalysis(
    BuildContext context, {
    required String imagePath,
  }) async {
    await Navigator.pushNamed(
      context,
      imageAnalysis,
      arguments: imagePath,
    );
  }
}
