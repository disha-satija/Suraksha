/// Central place for all app-wide constants.
/// Supabase keys are placeholders — fill in before running.
class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

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

  // ── Routing ───────────────────────────────────────────────────────────────
  static const String osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // ── Safety score thresholds ───────────────────────────────────────────────
  static const double safetyHighThreshold = 0.75;
  static const double safetyMediumThreshold = 0.50;

  // ── Connectivity ──────────────────────────────────────────────────────────
  static const Duration syncRetryInterval = Duration(seconds: 30);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefGuardianName = 'guardian_name';
  static const String prefGuardianPhone = 'guardian_phone';
  static const String prefUserName = 'user_name';
}
