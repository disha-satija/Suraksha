# Empower Her Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the Suraksha Flutter app to the "Empower Her" red/black/white Poppins design, add a 4-item bottom navigation bar, add a community Contribute (yes/no) verification flow, and add real offline map tile download.

**Architecture:** The app is MVVM with Provider DI wired in `lib/main.dart` (services → repositories → viewmodels → views). Theming is fully centralised: every widget already reads colours from `AppColors`, so the visual redesign is two files. New features follow the existing patterns exactly — Contribute reuses the Drift local-outbox → Supabase sync pattern from `IncidentRepository`, and offline maps plug into the existing `flutter_map` `TileLayer` via a caching `TileProvider`.

**Tech Stack:** Flutter 3.44.7 / Dart 3.12.2, `provider`, `flutter_map` 7.0.2, `drift` (SQLite), `supabase_flutter`, `flutter_map_tile_caching` 10.0.0 (new), bundled Poppins TTF assets (new).

## Global Constraints

- Work happens inside `c:\Downloads\Suraksha\suraksha` (the Flutter project root). All relative paths below are from there.
- Run all Flutter commands from that directory.
- **Known-bad baseline, measured 2026-08-07:** `flutter test` currently *fails* — `test/widget_test.dart` does not compile. `flutter analyze` reports **15 issues: 6 errors (all in `test/widget_test.dart`) and 9 infos** (pre-existing `prefer_const_constructors` / `deprecated_member_use` lints in `lib/views/screens/incident_screen.dart`). Task 0 fixes the 6 errors. The 9 infos in `incident_screen.dart` are out of scope and stay. So from Task 1 onward the bar is: **`flutter test` fully green, and `flutter analyze` reporting no more than those 9 pre-existing infos and zero errors.** "No issues found" is NOT the expected output — do not chase it.
- Pin exactly: `flutter_map_tile_caching: ^10.0.0`. It resolves against `flutter_map: ^7.0.2`; do NOT upgrade `flutter_map` to 8.x.
- **Licence note:** `flutter_map_tile_caching` is GPL-v3. Adding it puts a copyleft obligation on this app. This is an accepted, deliberate decision for this plan.
- Do NOT bring in the `google_fonts` package. It fetches fonts over the network at runtime, which contradicts this app's offline-first purpose. Poppins is bundled as local TTF assets instead.
- Brand palette, exact values: primary red `#F92A2A`, black `#000000`, white `#FFFFFF`.
- `AppColors.forScore()` must keep returning green → amber → red across the 0–1 range. The map's danger signalling depends on it and must not collapse into the brand red.
- Follow existing file conventions: 2-space indent, section header comments in the `// ── Name ────` style, `AppColors.*` for every colour (never a raw `Color(0x...)` in a view).
- Commit after every task using the message given in that task's final step.

---

### Task 0: Repair the broken baseline test

The existing `test/widget_test.dart` does not compile: it omits five `required`
parameters of `Incident` and calls a `toSupabaseJson()` method that no longer
exists (it was renamed `toSyncJson()` and its payload grew). Every later task
verifies with `flutter test`, so this has to be green first or none of those
checks mean anything.

**Files:**
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `Incident` and `Guardian` (existing models).
- Produces: a compiling, passing `flutter test` baseline.

- [ ] **Step 1: Confirm the failure first-hand**

Run: `flutter test`
Expected: FAIL — `Required named parameter 'lightingScore' must be provided.` and `The method 'toSupabaseJson' isn't defined for the type 'Incident'`.

- [ ] **Step 2: Fix the test against the real model**

Replace the whole of `test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/models/guardian.dart';
import 'package:suraksha/models/incident.dart';

void main() {
  test('guardian is configured only when both fields are present', () {
    expect(const Guardian(name: 'A', phone: '+919876543210').isConfigured, isTrue);
    expect(const Guardian(name: '', phone: '+919876543210').isConfigured, isFalse);
  });

  test('incident payload matches the backend contract', () {
    final incident = Incident(
      localId: 'event-1',
      latitude: 12.9,
      longitude: 77.6,
      crimeType: 'Harassment',
      description: 'Test report',
      lightingScore: 3.0,
      policeStationDistanceKm: 2.0,
      crowdDensity: 300.0,
      crimeCount: 5,
      weatherCondition: 'Clear',
      timeOfDay: 'Night',
      reportedAt: DateTime.utc(2026, 1, 1),
      isSynced: false,
    );

    expect(incident.toSyncJson(), {
      'clientEventId': 'event-1',
      'latitude': 12.9,
      'longitude': 77.6,
      'crimeType': 'Harassment',
      'description': 'Test report',
      'lightingScore': 3.0,
      'policeStationDistanceKm': 2.0,
      'crowdDensity': 300.0,
      'crimeCount': 5,
      'weatherCondition': 'Clear',
      'reportedAt': '2026-01-01T00:00:00.000Z',
    });
  });
}
```

Note `city`, `area`, and `incidentTimestamp` are absent from the expected map on
purpose — `toSyncJson` omits them when null.

- [ ] **Step 3: Run the test to verify it passes**

Run: `flutter test`
Expected: PASS — "+2: All tests passed!".

- [ ] **Step 4: Confirm the analyzer errors are gone**

Run: `flutter analyze`
Expected: 9 issues, all `info` level, all in `lib/views/screens/incident_screen.dart`. Zero errors. This is the baseline every later task is measured against.

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart
git commit -m "fix: repair widget_test against the current Incident model"
```

---

### Task 1: Empower Her theme — Poppins font + red/black/white palette

**Files:**
- Create: `assets/fonts/Poppins-Regular.ttf`, `assets/fonts/Poppins-Medium.ttf`, `assets/fonts/Poppins-SemiBold.ttf`, `assets/fonts/Poppins-Bold.ttf`
- Modify: `pubspec.yaml` (fonts section)
- Modify: `lib/core/constants/app_colors.dart` (full rewrite of values)
- Modify: `lib/main.dart:135-229` (the `ThemeData` block)
- Test: `test/theme_test.dart`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `AppColors.primary` = `Color(0xFFF92A2A)`, `AppColors.primaryLight` = `Color(0xFFFF6B6B)`, `AppColors.primaryDark` = `Color(0xFFC41E1E)`, `AppColors.onSurface` = `Color(0xFF000000)`, `AppColors.surface`/`AppColors.background` = `Color(0xFFFFFFFF)`, `AppColors.dangerRed` = `Color(0xFFF92A2A)`. `AppColors.safeGreen` and `AppColors.warningAmber` keep their existing values. Font family string `'Poppins'` available app-wide via `ThemeData.fontFamily`.

- [ ] **Step 1: Download the four Poppins weights**

```bash
mkdir -p assets/fonts
curl -sL -o assets/fonts/Poppins-Regular.ttf  "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf"
curl -sL -o assets/fonts/Poppins-Medium.ttf   "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Medium.ttf"
curl -sL -o assets/fonts/Poppins-SemiBold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-SemiBold.ttf"
curl -sL -o assets/fonts/Poppins-Bold.ttf     "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf"
ls -l assets/fonts/
```

Expected: four files, each roughly 150–170 KB. If any file is under 1 KB the download failed — do not proceed with a placeholder.

- [ ] **Step 2: Declare the fonts in `pubspec.yaml`**

Add a `fonts:` block under the existing `flutter:` section, directly after the `assets:` list (which ends with `- assets/data/demo_routes.json`):

```yaml
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
          weight: 400
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

- [ ] **Step 3: Write the failing theme test**

Create `test/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/core/constants/app_colors.dart';

void main() {
  test('brand palette matches the Empower Her design', () {
    expect(AppColors.primary, const Color(0xFFF92A2A));
    expect(AppColors.onSurface, const Color(0xFF000000));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.background, const Color(0xFFFFFFFF));
    expect(AppColors.dangerRed, AppColors.primary);
  });

  test('safety score colours stay green/amber/red so danger is still readable', () {
    expect(AppColors.forScore(0.9), AppColors.safeGreen);
    expect(AppColors.forScore(0.6), AppColors.warningAmber);
    expect(AppColors.forScore(0.2), AppColors.dangerRed);
    expect(AppColors.safeGreen, isNot(AppColors.primary));
    expect(AppColors.warningAmber, isNot(AppColors.primary));
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/theme_test.dart`
Expected: FAIL — `AppColors.primary` is still `Color(0xFF6940A5)`.

- [ ] **Step 5: Rewrite the palette**

Replace the whole of `lib/core/constants/app_colors.dart` with:

```dart
import 'package:flutter/material.dart';

/// Empower Her palette — red / black / white.
/// All logic that references AppColors continues to work —
/// only the actual colour values change here.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFFF92A2A); // Empower Her red
  static const Color primaryLight = Color(0xFFFF6B6B); // tints, ripples
  static const Color primaryDark  = Color(0xFFC41E1E); // pressed states

  // ── Semantic ──────────────────────────────────────────────────────────────
  // safeGreen and warningAmber are deliberately NOT brand colours — the map's
  // safety gradient must stay readable now that red is also the brand colour.
  static const Color safeGreen    = Color(0xFF2D9B6F);
  static const Color warningAmber = Color(0xFFD9730D);
  static const Color dangerRed    = primary;

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color background   = Color(0xFFFFFFFF);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFEDEDED); // 1-px divider
  static const Color hoverBg      = Color(0xFFFDF2F2); // subtle red-tinted hover

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color onSurface    = Color(0xFF000000);
  static const Color subtitle     = Color(0xFF6B6B6B);
  static const Color hint         = Color(0xFFADADAD);

  // ── Connectivity indicators ───────────────────────────────────────────────
  static const Color onlineIndicator        = safeGreen;
  static const Color offlineCachedIndicator = warningAmber;
  static const Color offlineStaleIndicator  = dangerRed;

  /// Flat colour for a 0–1 safety score.
  static Color forScore(double score) {
    if (score >= 0.75) return safeGreen;
    if (score >= 0.50) return warningAmber;
    return dangerRed;
  }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/theme_test.dart`
Expected: PASS (both tests).

- [ ] **Step 7: Update `ThemeData` for the Empower Her look**

In `lib/main.dart`, inside `SurakshaApp.build`, make these edits to the existing `ThemeData(...)`:

Change the font family line (currently `fontFamily: 'SF Pro Display',`) to:

```dart
        fontFamily: 'Poppins',
```

Replace the `elevatedButtonTheme` block with a pill-shaped red button:

```dart
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
```

Replace the `outlinedButtonTheme` block to match the pill shape:

```dart
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
```

Replace the `cardTheme` block with a softer, rounder card:

```dart
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
```

In `inputDecorationTheme`, change all three `BorderRadius.circular(8)` occurrences to `BorderRadius.circular(14)`.

In `appBarTheme`, bump the title size and weight so headings read like the reference:

```dart
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.2,
          ),
```

Leave `colorSchemeSeed: AppColors.primary`, `scaffoldBackgroundColor`, `dividerTheme`, `textButtonTheme`, and `snackBarTheme` as they are — they already resolve from `AppColors`.

- [ ] **Step 8: Verify the app compiles cleanly**

Run: `flutter pub get && flutter analyze`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml assets/fonts lib/core/constants/app_colors.dart lib/main.dart test/theme_test.dart
git commit -m "feat: apply Empower Her red/black/white theme with bundled Poppins"
```

---

### Task 2: Bottom navigation bar

**Files:**
- Create: `lib/views/widgets/bottom_nav_bar.dart`
- Modify: `lib/views/screens/map_screen.dart` (Scaffold at line ~78, drawer at lines ~746-815)
- Test: `test/bottom_nav_bar_test.dart`

**Interfaces:**
- Consumes: `AppColors.primary`, `AppColors.onSurface`, `AppColors.surface`, `AppColors.border` from Task 1.
- Produces: `SurakshaBottomNavBar` — a `StatelessWidget` with four required `VoidCallback` parameters: `onSafeRouting`, `onNearestSafeSpot`, `onGuardianMode`, `onReportIncident`. It performs no navigation itself.

- [ ] **Step 1: Write the failing widget test**

Create `test/bottom_nav_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/views/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('renders the four safety actions and fires the right callback',
      (tester) async {
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SurakshaBottomNavBar(
            onSafeRouting: () => tapped.add('routing'),
            onNearestSafeSpot: () => tapped.add('spot'),
            onGuardianMode: () => tapped.add('guardian'),
            onReportIncident: () => tapped.add('incident'),
          ),
        ),
      ),
    );

    expect(find.text('Safe Routing'), findsOneWidget);
    expect(find.text('Safe Spot'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.text('Safe Routing'));
    await tester.tap(find.text('Safe Spot'));
    await tester.tap(find.text('Guardian'));
    await tester.tap(find.text('Report'));
    await tester.pump();

    expect(tapped, ['routing', 'spot', 'guardian', 'incident']);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/bottom_nav_bar_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:suraksha/views/widgets/bottom_nav_bar.dart'`.

- [ ] **Step 3: Create the widget**

Create `lib/views/widgets/bottom_nav_bar.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Persistent quick-action bar shown at the bottom of the safety map.
///
/// This is a launcher, not a tab controller — the map stays mounted underneath
/// and each action pushes its own screen. It performs no navigation itself so
/// it stays independent of any one screen's state.
class SurakshaBottomNavBar extends StatelessWidget {
  final VoidCallback onSafeRouting;
  final VoidCallback onNearestSafeSpot;
  final VoidCallback onGuardianMode;
  final VoidCallback onReportIncident;

  const SurakshaBottomNavBar({
    super.key,
    required this.onSafeRouting,
    required this.onNearestSafeSpot,
    required this.onGuardianMode,
    required this.onReportIncident,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavAction(
                icon: Icons.alt_route_rounded,
                label: 'Safe Routing',
                onTap: onSafeRouting,
              ),
              _NavAction(
                icon: Icons.place_rounded,
                label: 'Safe Spot',
                onTap: onNearestSafeSpot,
              ),
              _NavAction(
                icon: Icons.shield_rounded,
                label: 'Guardian',
                onTap: onGuardianMode,
              ),
              _NavAction(
                icon: Icons.campaign_rounded,
                label: 'Report',
                onTap: onReportIncident,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/bottom_nav_bar_test.dart`
Expected: PASS.

- [ ] **Step 5: Extract the shared action handlers on MapScreen**

In `lib/views/screens/map_screen.dart`, add these four methods to `_MapScreenState`, immediately after `_openGoogleMapsTo` (which ends at line ~74) and before `Widget build`:

```dart
  // ── Bottom-bar / drawer actions ───────────────────────────────────────────
  void _openSafeRouting() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const RoutingScreen()));
  }

  void _openNearestSafeSpot() {
    final ssVm = context.read<SafeSpotViewModel>();
    if (ssVm.safeSpots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set your location first to find safe spots.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }
    _showSafeSpotListSheet(context, ssVm);
  }

  void _openGuardianMode() {
    Navigator.pushNamed(context, '/guardian');
  }

  void _openReportIncident() {
    final current = context.read<SafeSpotViewModel>().currentLocation ??
        context.read<MapViewModel>().center;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentScreen(
          latitude: current.latitude,
          longitude: current.longitude,
        ),
      ),
    );
  }
```

- [ ] **Step 6: Attach the bar to the Scaffold**

Add the import at the top of `lib/views/screens/map_screen.dart`, next to the other widget imports:

```dart
import '../widgets/bottom_nav_bar.dart';
```

Then in `Widget build`, add `bottomNavigationBar` to the `Scaffold` so it reads:

```dart
    return Scaffold(
      drawer: _buildDrawer(context),
      bottomNavigationBar: SurakshaBottomNavBar(
        onSafeRouting: _openSafeRouting,
        onNearestSafeSpot: _openNearestSafeSpot,
        onGuardianMode: _openGuardianMode,
        onReportIncident: _openReportIncident,
      ),
      body: Consumer2<MapViewModel, SafeSpotViewModel>(
```

- [ ] **Step 7: Remove the four duplicated drawer entries**

In `_buildDrawer`, delete these four items now that the bottom bar owns them:
- the `_DrawerItem` for `'Safe Routing'`
- the entire `Consumer<SafeSpotViewModel>` block wrapping the `'Nearest Safe Spot'` item
- the `_DrawerItem` for `'Guardian Mode'`
- the `_DrawerItem` for `'Report Incident'`

Keep the `'Safety Map'` item, the `Divider`, and the `'Settings'` item. After the edit the drawer body should be:

```dart
            _DrawerItem(
              icon: Icons.map_outlined,
              label: 'Safety Map',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
```

- [ ] **Step 8: Verify nothing broke**

Run: `flutter analyze && flutter test`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors; all tests pass.

If `flutter analyze` reports an unused import or unused element (for example `_DrawerItem`'s `badge` or `iconColor` parameter is now unused), remove the now-dead parameter from the `_DrawerItem` class rather than suppressing the warning.

- [ ] **Step 9: Commit**

```bash
git add lib/views/widgets/bottom_nav_bar.dart lib/views/screens/map_screen.dart test/bottom_nav_bar_test.dart
git commit -m "feat: add bottom navigation bar for the four primary safety actions"
```

---

### Task 3: Safe-spot verification storage and sync

**Files:**
- Modify: `lib/services/database_service.dart`
- Modify: `lib/services/database_service.g.dart` (regenerated, not hand-edited)
- Modify: `lib/services/supabase_service.dart`
- Create: `lib/models/safe_spot_verification.dart`
- Create: `lib/repositories/contribute_repository.dart`
- Test: `test/contribute_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SupabaseService`, `ConnectivityService` (all existing).
- Produces:
  - `class SafeSpotVerification` with fields `String localId`, `String spotId`, `String spotName`, `String question`, `bool answer`, `DateTime answeredAt`, `bool isSynced`, and `Map<String, dynamic> toSyncJson()`.
  - `AppDatabase.insertVerification(SafeSpotVerification)`, `AppDatabase.getUnsyncedVerifications() → Future<List<SafeSpotVerification>>` (maps Drift rows back to the model), `AppDatabase.markVerificationSynced(String localId)`, `AppDatabase.getVerifiedSpotIdsSince(DateTime cutoff) → Future<Set<String>>`.
  - `class ContributeRepository` with constructor `ContributeRepository({required AppDatabase db, required SupabaseService supabase, required ConnectivityService connectivity})` and methods `Future<void> submitVerification(SafeSpotVerification)`, `Future<Set<String>> recentlyVerifiedSpotIds()`, `Future<void> syncPending()`, `Future<void> syncOnConnectivityRestore()`.
  - `SupabaseService.syncSafeSpotVerification(SafeSpotVerification) → Future<void>`.

- [ ] **Step 1: Create the model**

Create `lib/models/safe_spot_verification.dart`:

```dart
/// A single community yes/no answer about a safe spot.
///
/// Written locally first, then pushed to the backend — the same outbox pattern
/// used by [Incident].
class SafeSpotVerification {
  final String localId;
  final String spotId;
  final String spotName;
  final String question;
  final bool answer;
  final DateTime answeredAt;
  final bool isSynced;

  const SafeSpotVerification({
    required this.localId,
    required this.spotId,
    required this.spotName,
    required this.question,
    required this.answer,
    required this.answeredAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toSyncJson() => {
        'clientEventId': localId,
        'safeSpotId': spotId,
        'question': question,
        'answer': answer,
        'answeredAt': answeredAt.toUtc().toIso8601String(),
      };
}
```

- [ ] **Step 2: Add the Drift table and queries**

In `lib/services/database_service.dart`:

Add the import next to the existing model imports:

```dart
import '../models/safe_spot_verification.dart';
```

Add the table definition after the `LocationQueue` class:

```dart
class SafeSpotVerifications extends Table {
  TextColumn get localId => text()();
  TextColumn get spotId => text()();
  TextColumn get spotName => text()();
  TextColumn get question => text()();
  BoolColumn get answer => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}
```

Register it on the database annotation:

```dart
@DriftDatabase(tables: [IncidentOutbox, LocationQueue, SafeSpotVerifications])
```

Bump the schema version:

```dart
  @override
  int get schemaVersion => 3;
```

Add the migration branch inside `onUpgrade`, after the existing `if (from < 2) { ... }` block:

```dart
          if (from < 3) {
            // v2 → v3: community safe-spot verifications
            await m.createTable(safeSpotVerifications);
          }
```

Add the query methods at the end of the `AppDatabase` class, after `markLocationSynced`:

```dart
  // ── Safe spot verifications ──────────────────────────────────────────────────

  Future<void> insertVerification(SafeSpotVerification verification) async {
    await into(safeSpotVerifications).insert(
      SafeSpotVerificationsCompanion.insert(
        localId: verification.localId,
        spotId: verification.spotId,
        spotName: verification.spotName,
        question: verification.question,
        answer: verification.answer,
        answeredAt: verification.answeredAt,
      ),
    );
  }

  Future<List<SafeSpotVerification>> getUnsyncedVerifications() async {
    final rows = await (select(safeSpotVerifications)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    return rows
        .map((r) => SafeSpotVerification(
              localId: r.localId,
              spotId: r.spotId,
              spotName: r.spotName,
              question: r.question,
              answer: r.answer,
              answeredAt: r.answeredAt,
              isSynced: r.isSynced,
            ))
        .toList();
  }

  Future<void> markVerificationSynced(String localId) async {
    await (update(safeSpotVerifications)
          ..where((t) => t.localId.equals(localId)))
        .write(const SafeSpotVerificationsCompanion(
          isSynced: Value(true),
        ));
  }

  /// IDs of spots this device has already answered about since [cutoff].
  /// Used to avoid asking the same question twice.
  Future<Set<String>> getVerifiedSpotIdsSince(DateTime cutoff) async {
    final rows = await (select(safeSpotVerifications)
          ..where((t) => t.answeredAt.isBiggerOrEqualValue(cutoff)))
        .get();
    return rows.map((r) => r.spotId).toSet();
  }
```

- [ ] **Step 3: Regenerate the Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: "Succeeded after ..." and `lib/services/database_service.g.dart` now contains `SafeSpotVerificationsData` / `SafeSpotVerificationsCompanion`.

Verify: `grep -c "SafeSpotVerificationsCompanion" lib/services/database_service.g.dart` returns a number greater than 0.

- [ ] **Step 4: Add the backend sync call**

In `lib/services/supabase_service.dart`, add the import next to the other model imports:

```dart
import '../models/safe_spot_verification.dart';
```

Add this method after `syncIncident`:

```dart
  /// Pushes a community safe-spot verification to the backend.
  Future<void> syncSafeSpotVerification(SafeSpotVerification verification) async {
    await _api.post('/safe-spots/verifications', verification.toSyncJson());
  }
```

- [ ] **Step 5: Write the failing repository test**

Create `test/contribute_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/models/safe_spot_verification.dart';

void main() {
  test('verification sync payload matches the backend contract', () {
    final verification = SafeSpotVerification(
      localId: 'verify-1',
      spotId: 'spot-42',
      spotName: 'Connaught Place Police Station',
      question: 'Is Connaught Place Police Station well-lit at night?',
      answer: true,
      answeredAt: DateTime.utc(2026, 1, 1),
    );

    expect(verification.toSyncJson(), {
      'clientEventId': 'verify-1',
      'safeSpotId': 'spot-42',
      'question': 'Is Connaught Place Police Station well-lit at night?',
      'answer': true,
      'answeredAt': '2026-01-01T00:00:00.000Z',
    });
  });

  test('a verification is unsynced until the backend confirms it', () {
    final verification = SafeSpotVerification(
      localId: 'verify-2',
      spotId: 'spot-7',
      spotName: 'City Hospital',
      question: 'Is City Hospital still open and operating?',
      answer: false,
      answeredAt: DateTime.utc(2026, 1, 2),
    );

    expect(verification.isSynced, isFalse);
  });
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/contribute_repository_test.dart`
Expected: PASS — the model was written in Step 1, so this confirms the contract rather than driving new code. If it fails, the payload keys in `toSyncJson` do not match; fix the model, not the test.

- [ ] **Step 7: Create the repository**

Create `lib/repositories/contribute_repository.dart`:

```dart
import '../models/safe_spot_verification.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

/// Manages community safe-spot verifications — writes locally first,
/// syncs when online. Mirrors [IncidentRepository]'s outbox pattern.
class ContributeRepository {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;

  /// How long an answered spot stays out of the question pool.
  static const Duration verificationCooldown = Duration(days: 30);

  ContributeRepository({
    required AppDatabase db,
    required SupabaseService supabase,
    required ConnectivityService connectivity,
  })  : _db = db,
        _supabase = supabase,
        _connectivity = connectivity;

  /// Save an answer locally and attempt immediate sync if online.
  Future<void> submitVerification(SafeSpotVerification verification) async {
    await _db.insertVerification(verification);
    if (_connectivity.isOnline) {
      try {
        await _supabase.syncSafeSpotVerification(verification);
        await _db.markVerificationSynced(verification.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// Spots already answered about within the cooldown window.
  Future<Set<String>> recentlyVerifiedSpotIds() =>
      _db.getVerifiedSpotIdsSince(DateTime.now().subtract(verificationCooldown));

  /// Push all unsynced local verifications to the backend.
  Future<void> syncPending() async {
    final pending = await _db.getUnsyncedVerifications();
    for (final verification in pending) {
      try {
        await _supabase.syncSafeSpotVerification(verification);
        await _db.markVerificationSynced(verification.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// Call this when connectivity is restored.
  Future<void> syncOnConnectivityRestore() => syncPending();
}
```

- [ ] **Step 8: Verify everything compiles and passes**

Run: `flutter analyze && flutter test`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors; all tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/models/safe_spot_verification.dart lib/repositories/contribute_repository.dart lib/services/database_service.dart lib/services/database_service.g.dart lib/services/supabase_service.dart test/contribute_repository_test.dart
git commit -m "feat: store and sync community safe-spot verifications"
```

---

### Task 4: Contribute screen

**Files:**
- Create: `lib/viewmodels/contribute_viewmodel.dart`
- Create: `lib/views/screens/contribute_screen.dart`
- Modify: `lib/main.dart` (repository construction, connectivity listener, provider list)
- Modify: `lib/views/screens/map_screen.dart` (drawer entry)
- Test: `test/contribute_screen_test.dart`

**Interfaces:**
- Consumes: `ContributeRepository` (Task 3), `SafeSpotViewModel.safeSpots` (existing, `List<SafeSpot>`), `SafeSpot.id` / `SafeSpot.name` (existing), `AppColors` (Task 1).
- Produces:
  - `class ContributeQuestion` with `final SafeSpot spot`, `final String text`, and `String get spotId`.
  - `class ContributeViewModel extends ChangeNotifier` with constructor `ContributeViewModel({required ContributeRepository repo})`, getters `List<ContributeQuestion> questions`, `int answeredCount`, `bool isLoading`, `bool get isComplete`, and methods `Future<void> loadQuestions(List<SafeSpot> nearbySpots)` and `Future<void> answer(ContributeQuestion question, bool value)`.
  - `class ContributeScreen extends StatefulWidget` with a `const ContributeScreen({super.key})` constructor.

- [ ] **Step 1: Create the view model**

Create `lib/viewmodels/contribute_viewmodel.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../models/safe_spot.dart';
import '../models/safe_spot_verification.dart';
import '../repositories/contribute_repository.dart';

/// One yes/no prompt about a specific safe spot.
class ContributeQuestion {
  final SafeSpot spot;
  final String text;

  const ContributeQuestion({required this.spot, required this.text});

  String get spotId => spot.id;
}

/// Drives the Contribute screen — picks unverified nearby spots, asks short
/// yes/no questions about them, and records the answers.
class ContributeViewModel extends ChangeNotifier {
  final ContributeRepository _repo;

  ContributeViewModel({required ContributeRepository repo}) : _repo = repo;

  /// Never ask more than this many questions in one sitting.
  static const int maxQuestions = 2;

  List<ContributeQuestion> _questions = [];
  int _answeredCount = 0;
  bool _isLoading = false;

  List<ContributeQuestion> get questions => _questions;
  int get answeredCount => _answeredCount;
  bool get isLoading => _isLoading;
  bool get isComplete => !_isLoading && _answeredCount >= _questions.length;

  /// Build the question list from spots the user hasn't answered about recently.
  Future<void> loadQuestions(List<SafeSpot> nearbySpots) async {
    _isLoading = true;
    _answeredCount = 0;
    notifyListeners();

    final alreadyVerified = await _repo.recentlyVerifiedSpotIds();
    final candidates = nearbySpots
        .where((s) => !alreadyVerified.contains(s.id))
        .take(maxQuestions)
        .toList();

    _questions = [
      for (var i = 0; i < candidates.length; i++)
        ContributeQuestion(
          spot: candidates[i],
          // Alternate the two templates so consecutive cards differ.
          text: i.isEven
              ? 'Is ${candidates[i].name} well-lit at night?'
              : 'Is ${candidates[i].name} still open and operating?',
        ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  /// Record a yes/no answer and advance the progress counter.
  Future<void> answer(ContributeQuestion question, bool value) async {
    _answeredCount++;
    notifyListeners();

    await _repo.submitVerification(
      SafeSpotVerification(
        localId: '${question.spotId}-${DateTime.now().microsecondsSinceEpoch}',
        spotId: question.spotId,
        spotName: question.spot.name,
        question: question.text,
        answer: value,
        answeredAt: DateTime.now(),
      ),
    );
  }
}
```

- [ ] **Step 2: Create the screen**

Create `lib/views/screens/contribute_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/contribute_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';

/// Community contribution screen — short yes/no questions about nearby safe
/// spots that help keep the safety data accurate for everyone else.
class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final Set<String> _answered = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spots = context.read<SafeSpotViewModel>().safeSpots;
      context.read<ContributeViewModel>().loadQuestions(spots);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contribute')),
      body: Consumer<ContributeViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.questions.isEmpty) {
            return const _EmptyState(
              icon: Icons.explore_off_rounded,
              title: 'Nothing to verify right now',
              message:
                  'Set your location on the map to find safe spots near you, '
                  'then come back to help others.',
            );
          }
          if (vm.isComplete) {
            return const _EmptyState(
              icon: Icons.volunteer_activism_rounded,
              title: 'Thank you!',
              message:
                  'Your answers make these safe spots more reliable for every '
                  'woman using Suraksha.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const Text(
                'Help others stay safe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Answer a couple of quick questions about places near you.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.subtitle, height: 1.4),
              ),
              const SizedBox(height: 20),
              _ProgressRow(
                answered: vm.answeredCount,
                total: vm.questions.length,
              ),
              const SizedBox(height: 20),
              for (final question in vm.questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QuestionCard(
                    question: question,
                    isAnswered: _answered.contains(question.spotId),
                    onAnswer: (value) {
                      setState(() => _answered.add(question.spotId));
                      vm.answer(question, value);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Progress row ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int answered;
  final int total;

  const _ProgressRow({required this.answered, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$answered/$total answered',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

// ── Question card ────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final ContributeQuestion question;
  final bool isAnswered;
  final ValueChanged<bool> onAnswer;

  const _QuestionCard({
    required this.question,
    required this.isAnswered,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.spot.category.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (isAnswered)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.safeGreen),
                SizedBox(width: 8),
                Text(
                  'Thanks — recorded',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.safeGreen),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAnswer(true),
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAnswer(false),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Empty / done state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.subtitle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire the repository and view model into DI**

In `lib/main.dart`:

Add the imports next to the matching existing ones:

```dart
import 'repositories/contribute_repository.dart';
import 'viewmodels/contribute_viewmodel.dart';
```

Construct the repository in the "Build repositories" section, after `routingRepo`:

```dart
  final contributeRepo = ContributeRepository(
    db: db,
    supabase: supabaseService,
    connectivity: connectivityService,
  );
```

Add it to the connectivity-restore listener so pending answers flush with everything else:

```dart
  connectivityService.statusStream.listen((status) {
    if (status == ConnectivityStatus.online) {
      incidentRepo.syncOnConnectivityRestore();
      guardianRepo.syncOnConnectivityRestore();
      contributeRepo.syncOnConnectivityRestore();
      connectivityService.markCacheUpdated();
    }
  });
```

Register the view model in the `MultiProvider` list, after the `SafeSpotViewModel` entry:

```dart
        ChangeNotifierProvider(
          create: (_) => ContributeViewModel(repo: contributeRepo),
        ),
```

- [ ] **Step 4: Add the drawer entry**

In `lib/views/screens/map_screen.dart`, add the import:

```dart
import 'contribute_screen.dart';
```

In `_buildDrawer`, insert this item between the `'Safety Map'` item and the `Divider`:

```dart
            _DrawerItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Contribute',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContributeScreen()));
              },
            ),
```

- [ ] **Step 5: Write the failing view-model test**

This tests the real `ContributeViewModel` against a fake repository. The fake uses
`implements ContributeRepository` (not `extends`) so it needs no database, no
network, and no super-constructor call.

Create `test/contribute_viewmodel_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/models/safe_spot.dart';
import 'package:suraksha/models/safe_spot_verification.dart';
import 'package:suraksha/repositories/contribute_repository.dart';
import 'package:suraksha/viewmodels/contribute_viewmodel.dart';

class _FakeContributeRepository implements ContributeRepository {
  _FakeContributeRepository({this.alreadyVerified = const {}});

  final Set<String> alreadyVerified;
  final List<SafeSpotVerification> submitted = [];

  @override
  Future<Set<String>> recentlyVerifiedSpotIds() async => alreadyVerified;

  @override
  Future<void> submitVerification(SafeSpotVerification verification) async {
    submitted.add(verification);
  }

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> syncOnConnectivityRestore() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SafeSpot _spot(String id, String name) => SafeSpot(
      id: id,
      name: name,
      address: 'Somewhere',
      lat: 28.6,
      lng: 77.2,
      category: SafeSpotCategory.policeStation,
      safetyScore: 0.9,
      distanceKm: 0.4,
      whySafe: 'Staffed around the clock.',
    );

void main() {
  test('builds at most two questions from unverified nearby spots', () async {
    final repo = _FakeContributeRepository();
    final vm = ContributeViewModel(repo: repo);

    await vm.loadQuestions([
      _spot('spot-1', 'MG Road Police Station'),
      _spot('spot-2', 'City Hospital'),
      _spot('spot-3', 'Central Metro'),
    ]);

    expect(vm.questions, hasLength(2));
    expect(vm.questions[0].text, 'Is MG Road Police Station well-lit at night?');
    expect(vm.questions[1].text, 'Is City Hospital still open and operating?');
    expect(vm.isLoading, isFalse);
    expect(vm.isComplete, isFalse);
  });

  test('skips spots this device already answered about', () async {
    final repo = _FakeContributeRepository(alreadyVerified: {'spot-1'});
    final vm = ContributeViewModel(repo: repo);

    await vm.loadQuestions([
      _spot('spot-1', 'MG Road Police Station'),
      _spot('spot-2', 'City Hospital'),
    ]);

    expect(vm.questions, hasLength(1));
    expect(vm.questions.single.spotId, 'spot-2');
  });

  test('answering records the verification and advances progress', () async {
    final repo = _FakeContributeRepository();
    final vm = ContributeViewModel(repo: repo);
    await vm.loadQuestions([_spot('spot-1', 'MG Road Police Station')]);

    await vm.answer(vm.questions.single, true);

    expect(vm.answeredCount, 1);
    expect(vm.isComplete, isTrue);
    expect(repo.submitted, hasLength(1));
    expect(repo.submitted.single.spotId, 'spot-1');
    expect(repo.submitted.single.answer, isTrue);
    expect(repo.submitted.single.question,
        'Is MG Road Police Station well-lit at night?');
  });

  test('no nearby spots means no questions and nothing to submit', () async {
    final repo = _FakeContributeRepository();
    final vm = ContributeViewModel(repo: repo);

    await vm.loadQuestions([]);

    expect(vm.questions, isEmpty);
    expect(repo.submitted, isEmpty);
  });
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/contribute_viewmodel_test.dart`
Expected: PASS — all four tests.

If the analyzer complains that `_FakeContributeRepository` is missing members, that
means `ContributeRepository` gained a method: add a matching override to the fake.
Do NOT delete the `implements` clause or loosen the production constructor.

- [ ] **Step 7: Verify the whole app still builds**

Run: `flutter analyze && flutter test`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors; all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/viewmodels/contribute_viewmodel.dart lib/views/screens/contribute_screen.dart lib/main.dart lib/views/screens/map_screen.dart test/contribute_viewmodel_test.dart
git commit -m "feat: add Contribute screen with yes/no safe-spot verification"
```

---

### Task 5: Offline tile caching backend

**Files:**
- Modify: `pubspec.yaml` (dependency)
- Modify: `lib/core/constants/app_constants.dart` (store name constant)
- Modify: `lib/main.dart` (FMTC init)
- Modify: `lib/views/screens/map_screen.dart:227-231` (TileLayer)
- Modify: `lib/views/screens/guardian_screen.dart:73-77` and `:337-340` (TileLayers)

**Interfaces:**
- Consumes: `AppConstants.onlineTileUrl` (existing).
- Produces: `AppConstants.offlineTileStoreName` = `'suraksha_offline_tiles'`, and a globally initialised FMTC ObjectBox backend with that store created. Task 6 downloads into this same store.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add flutter_map_tile_caching`

Then confirm the resolved version did not drag `flutter_map` forward:

Run: `grep -E "flutter_map:|flutter_map_tile_caching:" pubspec.yaml`
Expected: `flutter_map: ^7.0.2` unchanged and `flutter_map_tile_caching: ^10.0.0`. If `flutter_map` was bumped to 8.x, revert `pubspec.yaml` and pin `flutter_map_tile_caching: ^10.0.0` by hand, then re-run `flutter pub get`.

- [ ] **Step 2: Add the store name constant**

In `lib/core/constants/app_constants.dart`, add under the `// ── Map ──` section, directly after `onlineTileUrl`:

```dart
  // FMTC store that holds downloaded offline tiles
  static const String offlineTileStoreName = 'suraksha_offline_tiles';
```

- [ ] **Step 3: Initialise the FMTC backend at startup**

In `lib/main.dart`, add the import:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'core/constants/app_constants.dart';
```

(If `app_constants.dart` is already imported, do not add it twice.)

In `main()`, after the `connectivityService` initialisation and before `settingsService`, add:

```dart
  // Offline tile cache is best-effort — a failure here must never block launch,
  // it only means the map falls back to online-only tiles.
  try {
    await FMTCObjectBoxBackend().initialise();
    await const FMTCStore(AppConstants.offlineTileStoreName).manage.create();
  } catch (_) {
    // Tile caching unavailable — map still works online
  }
```

- [ ] **Step 4: Point the map's TileLayer at the cache**

In `lib/views/screens/map_screen.dart`, add the import:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

Replace the `TileLayer` in `_buildMap` (lines ~227-231) with:

```dart
        TileLayer(
          urlTemplate: AppConstants.onlineTileUrl,
          userAgentPackageName: 'com.suraksha.app',
          tileProvider: FMTCTileProvider(
            stores: const {
              AppConstants.offlineTileStoreName:
                  BrowseStoreStrategy.readUpdateCreate,
            },
            loadingStrategy: BrowseLoadingStrategy.cacheFirst,
          ),
        ),
```

Note the `fallbackUrl` is dropped — it pointed at the same OSM host as `urlTemplate`, so it added nothing, and FMTC's cache is the real fallback now.

- [ ] **Step 5: Do the same for both Guardian maps**

In `lib/views/screens/guardian_screen.dart`, add the import:

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
```

Replace **both** `TileLayer` blocks (around lines 73 and 337) with:

```dart
                        TileLayer(
                          urlTemplate: AppConstants.onlineTileUrl,
                          userAgentPackageName: 'com.suraksha.app',
                          tileProvider: FMTCTileProvider(
                            stores: const {
                              AppConstants.offlineTileStoreName:
                                  BrowseStoreStrategy.readUpdateCreate,
                            },
                            loadingStrategy: BrowseLoadingStrategy.cacheFirst,
                          ),
                        ),
```

Adjust the leading indentation to match each site. If `app_constants.dart` is not yet imported in this file, add `import '../../core/constants/app_constants.dart';`.

- [ ] **Step 6: Verify it compiles and the app launches**

Run: `flutter analyze`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors.

Run: `flutter build apk --debug`
Expected: build succeeds.

If the Android build fails with an ObjectBox `minSdkVersion` error, set the floor explicitly in `android/app/build.gradle.kts` — change `minSdk = flutter.minSdkVersion` to `minSdk = maxOf(flutter.minSdkVersion, 23)` and rebuild. Do not lower any other SDK setting.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/constants/app_constants.dart lib/main.dart lib/views/screens/map_screen.dart lib/views/screens/guardian_screen.dart
git commit -m "feat: cache map tiles locally via flutter_map_tile_caching"
```

---

### Task 6: Download Offline Maps screen

**Files:**
- Create: `lib/views/screens/download_offline_maps_screen.dart`
- Modify: `lib/views/screens/map_screen.dart` (drawer entry)

**Interfaces:**
- Consumes: `AppConstants.offlineTileStoreName` and the initialised FMTC backend (Task 5), `MapViewModel.center` (existing, `LatLng`), `AppColors` (Task 1).
- Produces: `class DownloadOfflineMapsScreen extends StatefulWidget` with a `const DownloadOfflineMapsScreen({super.key})` constructor.

- [ ] **Step 1: Create the screen**

Create `lib/views/screens/download_offline_maps_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/map_viewmodel.dart';

enum _DownloadStage { idle, counting, downloading, done, failed }

/// Lets the user download the map tiles around a chosen area so the safety map
/// keeps working with no connection at all.
class DownloadOfflineMapsScreen extends StatefulWidget {
  const DownloadOfflineMapsScreen({super.key});

  @override
  State<DownloadOfflineMapsScreen> createState() =>
      _DownloadOfflineMapsScreenState();
}

class _DownloadOfflineMapsScreenState extends State<DownloadOfflineMapsScreen> {
  static const _store = FMTCStore(AppConstants.offlineTileStoreName);

  final MapController _mapController = MapController();

  RangeValues _zoomRange = const RangeValues(12, 16);
  _DownloadStage _stage = _DownloadStage.idle;
  int _tileCount = 0;
  double _progress = 0;
  int _downloadedTiles = 0;
  String _errorMessage = '';
  StreamSubscription<DownloadProgress>? _progressSub;

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  /// The visible map area is what gets downloaded.
  LatLngBounds get _visibleBounds => _mapController.camera.visibleBounds;

  TileLayer get _tileLayer => TileLayer(
        urlTemplate: AppConstants.onlineTileUrl,
        userAgentPackageName: 'com.suraksha.app',
      );

  DownloadableRegion get _region => RectangleRegion(_visibleBounds).toDownloadable(
        minZoom: _zoomRange.start.round(),
        maxZoom: _zoomRange.end.round(),
        options: _tileLayer,
      );

  Future<void> _estimate() async {
    setState(() => _stage = _DownloadStage.counting);
    try {
      final count = await _store.download.countTiles(_region);
      if (!mounted) return;
      setState(() {
        _tileCount = count;
        _stage = _DownloadStage.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _DownloadStage.failed;
        _errorMessage = 'Could not measure this area. $e';
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _stage = _DownloadStage.downloading;
      _progress = 0;
      _downloadedTiles = 0;
      _errorMessage = '';
    });

    try {
      final result = _store.download.startForeground(
        region: _region,
        parallelThreads: 3,
        skipExistingTiles: true,
        // OSM's tile usage policy asks for gentle bulk access.
        rateLimit: 20,
      );

      _progressSub = result.downloadProgress.listen(
        (progress) {
          if (!mounted) return;
          setState(() {
            _progress = (progress.percentageProgress / 100).clamp(0.0, 1.0);
            _downloadedTiles = progress.attemptedTilesCount;
            _tileCount = progress.maxTilesCount;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _stage = _DownloadStage.done);
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _stage = _DownloadStage.failed;
            _errorMessage =
                'Download stopped. Check your connection and try again.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _DownloadStage.failed;
        _errorMessage = 'Could not start the download. $e';
      });
    }
  }

  Future<void> _cancelDownload() async {
    await _store.download.cancel();
    await _progressSub?.cancel();
    if (!mounted) return;
    setState(() => _stage = _DownloadStage.idle);
  }

  /// OSM raster tiles average roughly 15 KB each.
  String get _estimatedSize {
    final mb = (_tileCount * 15) / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final center = context.read<MapViewModel>().center;

    return Scaffold(
      appBar: AppBar(title: const Text('Download Offline Maps')),
      body: Column(
        children: [
          // ── Area preview ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(center.latitude, center.longitude),
                    initialZoom: AppConstants.demoDefaultZoom,
                  ),
                  children: [_tileLayer],
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _HintPill(
                    text: 'Pan and zoom to frame the area you want offline',
                  ),
                ),
              ],
            ),
          ),

          // ── Controls ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail level  ·  zoom ${_zoomRange.start.round()}–${_zoomRange.end.round()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  RangeSlider(
                    values: _zoomRange,
                    min: 8,
                    max: 18,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    labels: RangeLabels(
                      '${_zoomRange.start.round()}',
                      '${_zoomRange.end.round()}',
                    ),
                    onChanged: _stage == _DownloadStage.downloading
                        ? null
                        : (values) => setState(() {
                              _zoomRange = values;
                              _tileCount = 0;
                            }),
                  ),
                  const SizedBox(height: 4),
                  _buildStatus(),
                  const SizedBox(height: 12),
                  _buildAction(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    switch (_stage) {
      case _DownloadStage.counting:
        return const Text(
          'Measuring this area…',
          style: TextStyle(fontSize: 13, color: AppColors.subtitle),
        );
      case _DownloadStage.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_downloadedTiles of $_tileCount tiles  ·  ${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
        );
      case _DownloadStage.done:
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.safeGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This area is available offline.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.safeGreen,
                ),
              ),
            ),
          ],
        );
      case _DownloadStage.failed:
        return Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
              ),
            ),
          ],
        );
      case _DownloadStage.idle:
        return Text(
          _tileCount == 0
              ? 'Measure the area to see how much space it needs.'
              : '$_tileCount tiles  ·  about $_estimatedSize',
          style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
        );
    }
  }

  Widget _buildAction() {
    switch (_stage) {
      case _DownloadStage.downloading:
        return OutlinedButton(
          onPressed: _cancelDownload,
          child: const Text('Cancel Download'),
        );
      case _DownloadStage.done:
        return ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        );
      case _DownloadStage.failed:
        return ElevatedButton(
          onPressed: _startDownload,
          child: const Text('Retry'),
        );
      case _DownloadStage.counting:
        return const ElevatedButton(
          onPressed: null,
          child: Text('Measuring…'),
        );
      case _DownloadStage.idle:
        return _tileCount == 0
            ? ElevatedButton(
                onPressed: _estimate,
                child: const Text('Measure This Area'),
              )
            : ElevatedButton(
                onPressed: _startDownload,
                child: const Text('Download for Offline Use'),
              );
    }
  }
}

// ── Hint pill ────────────────────────────────────────────────────────────────

class _HintPill extends StatelessWidget {
  final String text;

  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add the drawer entry**

In `lib/views/screens/map_screen.dart`, add the import:

```dart
import 'download_offline_maps_screen.dart';
```

In `_buildDrawer`, insert this item directly after the `'Contribute'` item added in Task 4:

```dart
            _DrawerItem(
              icon: Icons.download_for_offline_outlined,
              label: 'Download Offline Maps',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DownloadOfflineMapsScreen()));
              },
            ),
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze && flutter test`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors; all tests pass.

- [ ] **Step 4: Verify the download works on a device**

Run: `flutter run` on a connected Android device or emulator with network.

Then walk through:
1. Open the drawer → **Download Offline Maps**.
2. Tap **Measure This Area** — a tile count and MB estimate appear.
3. Tap **Download for Offline Use** — the progress bar advances and the tile counter climbs.
4. Wait for the green "This area is available offline." message, tap **Done**.
5. Put the device in airplane mode, force-close and relaunch the app.
6. Confirm the downloaded area still renders map tiles on the home map.

Record the actual observed result. If step 6 shows blank tiles, the store name in `AppConstants.offlineTileStoreName` does not match between the download screen and the map's `FMTCTileProvider` — check both before changing anything else.

- [ ] **Step 5: Commit**

```bash
git add lib/views/screens/download_offline_maps_screen.dart lib/views/screens/map_screen.dart
git commit -m "feat: add offline map area download screen"
```

---

### Task 7: Full-app verification

**Files:**
- Modify: any file needing a fix found during verification.

**Interfaces:**
- Consumes: everything from Tasks 1–6.
- Produces: a verified, clean build.

- [ ] **Step 1: Run the full static and test suite**

Run: `flutter analyze && flutter test`
Expected: analyze reports only the 9 pre-existing infos in `incident_screen.dart` and zero errors; every test passes. Paste the real output; do not summarise it as passing without it.

- [ ] **Step 2: Confirm no raw colours slipped into the views**

Run: `grep -rn "Color(0xFF" lib/views/`
Expected: only the single pre-existing star-rating amber `Color(0xFFF9A825)` in `lib/views/screens/map_screen.dart`. Any other hit is a theming regression — replace it with the matching `AppColors` constant.

- [ ] **Step 3: Confirm the purple palette is fully gone**

Run: `grep -rn "6940A5\|9B72CF\|4A2D7A\|SF Pro Display" lib/`
Expected: no matches.

- [ ] **Step 4: Walk the app on a device**

Run: `flutter run`

Check each of these and record what you actually saw:
1. Home map renders with the white/red theme and Poppins text.
2. Bottom bar shows four items: Safe Routing, Safe Spot, Guardian, Report.
3. Each bottom-bar item opens its screen; going back returns to the map with its state intact (location and safe-spot markers still there).
4. Drawer shows: Safety Map, Contribute, Download Offline Maps, Settings.
5. Contribute shows yes/no question cards when safe spots are loaded, and the thank-you state after answering both.
6. Tapping the map still opens the safety score card, and its score ring is still green/amber/red — not brand red for every score.
7. Guardian screen's SOS button is red and its map renders.

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve issues found during full-app verification"
```

If Step 1–4 turned up nothing to fix, skip this commit rather than creating an empty one.
