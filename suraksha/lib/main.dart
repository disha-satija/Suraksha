import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'services/onnx_service.dart';
import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'services/connectivity_service.dart';
import 'services/routing_service.dart';
import 'services/settings_service.dart';
import 'services/sms_service.dart';
import 'models/connectivity_state.dart';
import 'repositories/safety_repository.dart';
import 'repositories/incident_repository.dart';
import 'repositories/guardian_repository.dart';
import 'repositories/routing_repository.dart';
import 'viewmodels/map_viewmodel.dart';
import 'viewmodels/routing_viewmodel.dart';
import 'viewmodels/guardian_viewmodel.dart';
import 'viewmodels/incident_viewmodel.dart';
import 'views/screens/map_screen.dart';
import 'views/screens/guardian_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize services ─────────────────────────────────────────────────────
  // Supabase init is best-effort — placeholder keys mean offline-only mode for now.
  try {
    await SupabaseService.initialize();
  } catch (_) {
    // Supabase unavailable — app runs fully offline
  }

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  final settingsService = SettingsService();
  await settingsService.initialize();

  final onnxService = OnnxService();
  // ONNX init is deferred — MapViewModel calls it and handles failure gracefully

  final db = AppDatabase();

  final routingService = RoutingService();
  try {
    await routingService.initialize();
  } catch (_) {
    // Route cache unavailable — online routing still works
  }

  // ── Build repositories ──────────────────────────────────────────────────────
  final supabaseService = SupabaseService();

  final safetyRepo = SafetyRepository(onnxService: onnxService);
  final incidentRepo = IncidentRepository(
    db: db,
    supabase: supabaseService,
    connectivity: connectivityService,
  );
  final guardianRepo = GuardianRepository(
    db: db,
    supabase: supabaseService,
    connectivity: connectivityService,
    settings: settingsService,
    sms: SmsService(),
  );
  final routingRepo = RoutingRepository(
    routingService: routingService,
    connectivity: connectivityService,
  );

  // ── Sync on connectivity restore ────────────────────────────────────────────
  connectivityService.statusStream.listen((status) {
    if (status == ConnectivityStatus.online) {
      incidentRepo.syncOnConnectivityRestore();
      connectivityService.markCacheUpdated();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        // Services (read-only, no notify)
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<SettingsService>.value(value: settingsService),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => MapViewModel(
            safetyRepo: safetyRepo,
            connectivity: connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutingViewModel(routingRepo: routingRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => GuardianViewModel(
            guardianRepo: guardianRepo,
            connectivity: connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => IncidentViewModel(incidentRepo: incidentRepo),
        ),
      ],
      child: const SurakshaApp(),
    ),
  );
}

class SurakshaApp extends StatelessWidget {
  const SurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suraksha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // falls back to system font on Android
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const MapScreen(),
        '/guardian': (_) => const GuardianScreen(),
        '/guardian/watch': (ctx) {
          final userId =
              ModalRoute.of(ctx)!.settings.arguments as String? ??
                  'demo_user_001';
          return GuardianWatchScreen(trackedUserId: userId);
        },
      },
    );
  }
}
