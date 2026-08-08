/// Central place for all app-wide constants.
class AppConstants {
  AppConstants._();

  // ── Runtime configuration ────────────────────────────────────────────────
  // Pass these with --dart-define. No service credential belongs in the app.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String apiBaseUrl = String.fromEnvironment(
    'SURAKSHA_API_URL',
    defaultValue: 'http://172.20.10.4:3000/api/v1',
  );

  // ── Asset paths ───────────────────────────────────────────────────────────
  static const String onnxModelPath = 'assets/model/safety_model.onnx';
  static const String modelWeightsPath = 'assets/model/model_weights.json';
  static const String safetyGridPath = 'assets/data/safety_grid.json';
  static const String demoRoutesPath = 'assets/data/demo_routes.json';

  // ── Map ───────────────────────────────────────────────────────────────────
  // Delhi NCR bounding box for demo
  static const double demoLatMin = 28.40;
  static const double demoLatMax = 28.88;
  static const double demoLngMin = 76.84;
  static const double demoLngMax = 77.35;
  static const double demoDefaultLat = 28.6139;
  static const double demoDefaultLng = 77.2090;
  static const double demoDefaultZoom = 12.0;

  // Online tile URL (used when network available)
  static const String onlineTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // FMTC store that holds downloaded offline tiles
  static const String offlineTileStoreName = 'suraksha_offline_tiles';

  // ── Routing ───────────────────────────────────────────────────────────────

  // ── Safety score thresholds ───────────────────────────────────────────────
  static const double safetyHighThreshold = 0.75;
  static const double safetyMediumThreshold = 0.50;

  // ── Safety grid proximity gates ───────────────────────────────────────────
  // The bundled grid holds ONE centroid per area (50 areas, 10 cities), so the
  // nearest centroid can easily be a different part of the city. These gates
  // stop the app from claiming you are somewhere you are not.
  //
  //   <= areaLabelMaxKm : close enough to name the area as "your area"
  //   <= gridTrustMaxKm : usable as a nearby reference, but named as such
  //    > gridTrustMaxKm : no local coverage — ask the backend instead
  static const double areaLabelMaxKm = 3.0;
  static const double gridTrustMaxKm = 8.0;

  /// Sent to `GET /safety/score` so the server applies the same coverage gate.
  static const int gridTrustMaxMeters = 8000;

  // ── Connectivity ──────────────────────────────────────────────────────────
  static const Duration syncRetryInterval = Duration(seconds: 30);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefGuardianName = 'guardian_name';
  static const String prefGuardianPhone = 'guardian_phone';
  static const String prefUserName = 'user_name';
  static const String prefGuardianId = 'guardian_id';
  static const String prefSharingSessionId = 'sharing_session_id';
  static const String prefShareToken = 'share_token';
}
