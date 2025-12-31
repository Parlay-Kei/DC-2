import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config/supabase_config.dart';
import 'config/app_config.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug: Log environment configuration (stripped in release)
  Logger.info('App starting');
  Logger.debug('OneSignal configured: ${AppConfig.isOneSignalConfigured}');
  Logger.debug('Mapbox configured: ${AppConfig.isMapboxConfigured}');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Push Notifications (non-blocking, errors handled internally)
  NotificationService.instance.initialize();

  // Initialize Mapbox SDK with access token (must be done before any Mapbox widgets)
  if (AppConfig.isMapboxConfigured) {
    MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
    Logger.debug('Mapbox SDK initialized');
  }

  runApp(
    const ProviderScope(
      child: DirectCutsApp(),
    ),
  );
}

class DirectCutsApp extends ConsumerStatefulWidget {
  const DirectCutsApp({super.key});

  @override
  ConsumerState<DirectCutsApp> createState() => _DirectCutsAppState();
}

class _DirectCutsAppState extends ConsumerState<DirectCutsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for notifications
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh notification count
      Logger.debug('App resumed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Direct Cuts',
      debugShowCheckedModeBanner: false,
      theme: DCTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Wrap with error boundary
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
