import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/database_service.dart';
import 'core/services/camera_service.dart';
import 'core/services/ai_service.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'shared/theme/app_theme.dart';
import 'shared/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await _initializeServices();

  runApp(const LandMapperApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize database
    await DatabaseService().initialize();

    // Initialize AI service
    await AIService().initializeModels();

    // Initialize camera service
    await CameraService().initializeCamera();
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class LandMapperApp extends StatelessWidget {
  const LandMapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Land Mapper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRouter.generateRoute,
      home: const HomePage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
