import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/map/presentation/pages/land_measure_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static const String home = '/';
  static const String camera = '/camera';
  static const String map = '/map';
  static const String landMeasure = '/land-measure';
  static const String settings = '/settings';
  static const String landPointDetails = '/land-point-details';
  static const String imageAnalysis = '/image-analysis';

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
      case '/land-measure':
        return MaterialPageRoute(
          builder: (_) => const LandMeasurePage(),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
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

  static void navigateToCamera(BuildContext context) {
    Navigator.pushNamed(context, camera);
  }

  static void navigateToMap(BuildContext context) {
    Navigator.pushNamed(context, map);
  }

  static void navigateToLandMeasure(BuildContext context) {
    Navigator.pushNamed(context, landMeasure);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settings);
  }
}
