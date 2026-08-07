import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/map_tile_provider.dart';
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
import 'repositories/contribute_repository.dart';
import 'viewmodels/map_viewmodel.dart';
import 'viewmodels/routing_viewmodel.dart';
import 'viewmodels/guardian_viewmodel.dart';
import 'viewmodels/incident_viewmodel.dart';
import 'viewmodels/contribute_viewmodel.dart';
import 'services/safe_spot_service.dart';
import 'viewmodels/safe_spot_viewmodel.dart';
import 'views/screens/guardian_screen.dart';
import 'views/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize services ─────────────────────────────────────────────────────
  // Supabase init is best-effort — placeholder keys mean offline-only mode for now.
  // The 8-second timeout ensures a hanging DNS lookup can't stall startup indefinitely;
  // any exception (including TimeoutException) falls into the catch below.
  try {
    await SupabaseService.initialize()
        .timeout(const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Supabase init timed out'));
  } catch (_) {
    // Supabase unavailable — app runs fully offline
  }

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Offline tile cache is best-effort — a failure here must never block launch.
  // If it fails, MapTileProvider falls back to plain network tiles so the maps
  // still render whenever there is a connection.
  var offlineCacheReady = false;
  try {
    await FMTCObjectBoxBackend().initialise();
    await const FMTCStore(AppConstants.offlineTileStoreName).manage.create();
    offlineCacheReady = true;
  } catch (_) {
    // Tile caching unavailable — maps fall back to online-only tiles
  }
  MapTileProvider.markOfflineCacheReady(ready: offlineCacheReady);

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

  // Load the bundled safety grid up front — the home dashboard, safe-spot
  // fallback, and routing suggestions all read it, not just the map tab.
  try {
    await safetyRepo.initialize();
  } catch (_) {
    // Grid unavailable — scoring falls back to defaults
  }
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
  final contributeRepo = ContributeRepository(
    db: db,
    supabase: supabaseService,
    connectivity: connectivityService,
  );

  final safeSpotService = SafeSpotService(safetyRepo: safetyRepo);

  // ── Sync on connectivity restore ────────────────────────────────────────────
  connectivityService.statusStream.listen((status) {
    if (status == ConnectivityStatus.online) {
      incidentRepo.syncOnConnectivityRestore();
      guardianRepo.syncOnConnectivityRestore();
      contributeRepo.syncOnConnectivityRestore();
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
          create: (_) => IncidentViewModel(incidentRepo: incidentRepo, supabase: supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => SafeSpotViewModel(safeSpots: safeSpotService),
        ),
        ChangeNotifierProvider(
          create: (_) => ContributeViewModel(repo: contributeRepo),
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
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
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
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
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
            borderRadius: BorderRadius.circular(16),
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
        '/': (_) => const AuthGate(),
        '/guardian': (_) => const GuardianScreen(),
        '/guardian/watch': (ctx) {
          final shareToken = ModalRoute.of(ctx)!.settings.arguments as String? ?? '';
          return GuardianWatchScreen(shareToken: shareToken);
        },
      },
    );
  }
}
