import 'package:flutter/material.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import 'main_navigation.dart';

class AppRouter {
  static const String home = '/';
  static const String camera = '/camera';
  static const String map = '/map';
  static const String landMeasure = '/land-measure';
  static const String settings = '/settings';
  static const String savedPoints = '/saved-points';
  static const String landPointDetails = '/land-point-details';
  static const String imageAnalysis = '/image-analysis';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        );
      case '/camera':
        return MaterialPageRoute(
          builder: (_) => const CameraPage(),
        );
      case '/map':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 0),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 2),
        );
      case '/saved-points':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 1),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
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
    Navigator.pushNamedAndRemoveUntil(context, map, (route) => false);
  }

  static void navigateToLandMeasure(BuildContext context) {
    Navigator.pushNamed(context, landMeasure);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, settings, (route) => false);
  }

  static void navigateToSavedPoints(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, savedPoints, (route) => false);
  }
}
