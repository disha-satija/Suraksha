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
import 'services/groq_service.dart';
import 'viewmodels/safe_spot_viewmodel.dart';
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

  final groqService = GroqService();

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
        ChangeNotifierProvider(
          create: (_) => SafeSpotViewModel(groq: groqService),
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
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: AppColors.onSurface, size: 20),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          space: 1,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(
              color: AppColors.subtitle, fontSize: 14),
          hintStyle: const TextStyle(
              color: AppColors.hint, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.onSurface,
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
          behavior: SnackBarBehavior.floating,
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
