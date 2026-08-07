# Suraksha — Empower Her Redesign & Feature Expansion

**Date:** 2026-08-07
**Scope:** `suraksha/` Flutter app

## Goal

Restyle the Suraksha app to match the "Empower Her" UI/UX case study (red/black/white,
Poppins, rounded cards and pill buttons), add a persistent bottom navigation bar for the
four primary safety actions, add a community "Contribute" yes/no verification flow, and
add real offline map tile download.

## Current State

- `MapScreen` (`lib/views/screens/map_screen.dart`) is the home screen: a full-screen
  `flutter_map` with a hamburger `Drawer` as the only navigation mechanism.
- Palette lives in `lib/core/constants/app_colors.dart` (purple, Notion-inspired).
  `ThemeData` is built inline in `lib/main.dart`.
- Routing, Guardian, Incident, Settings screens already exist and are reachable from the drawer.
- `flutter_map ^7.0.2` renders online OSM tiles only. No tile caching of any kind.
- No bottom navigation bar exists anywhere in `lib/`.

## Design

### A. Theme & Typography

**Palette** — rewrite `lib/core/constants/app_colors.dart` values only; every existing
reference to `AppColors.*` keeps compiling.

| Token | New value | Note |
|---|---|---|
| `primary` | `#F92A2A` | Empower Her red |
| `primaryLight` | `#FF6B6B` | tints, ripples |
| `primaryDark` | `#C41E1E` | pressed states |
| `onSurface` | `#000000` | body text |
| `surface` | `#FFFFFF` | cards |
| `background` | `#FFFFFF` | scaffold |
| `dangerRed` | `#F92A2A` | now an alias of `primary` |
| `safeGreen` | `#2D9B6F` (unchanged) | safety-score gradient |
| `warningAmber` | `#D9730D` (unchanged) | safety-score gradient |

`AppColors.forScore()` logic is unchanged — the map/route score gradient must remain
green→amber→red so danger is still readable now that red is also the brand colour.

**Typography** — add the `google_fonts` package. Replace `fontFamily: 'SF Pro Display'`
in `main.dart` with a Poppins `textTheme`. Weights used: Regular (400), Medium (500),
SemiBold (600), Bold (700).

**ThemeData** — in `main.dart`: pill-shaped buttons (`borderRadius: 28` for primary CTAs),
`cardTheme` radius bumped to 16 with a soft border, `AppBarTheme` and
`inputDecorationTheme` recoloured to the new palette.

**Ripple** — audit existing screens (`guardian_screen.dart`, `incident_screen.dart`,
`routing_screen.dart`, `settings_screen.dart`, `auth_screen.dart`,
`widgets/safety_score_card.dart`, `widgets/connectivity_banner.dart`) for hardcoded
colours or font sizes that fight the new theme, and align them.

### B. Bottom Navigation Bar

New widget: `lib/views/widgets/bottom_nav_bar.dart`.

Four fixed items, styled like the reference (icon above label, active item red, inactive
grey, white bar with a top hairline border):

| Item | Icon | Action |
|---|---|---|
| Safe Routing | route | push `RoutingScreen` |
| Nearest Safe Spot | location pin | open existing nearby-safe-spots bottom sheet |
| Guardian Mode | shield | `Navigator.pushNamed('/guardian')` |
| Report Incident | megaphone | push `IncidentScreen` (with current/last-known lat/lng) |

The bar renders inside `MapScreen`'s `Scaffold` as `bottomNavigationBar`. `MapScreen`
remains the single home screen — this is a quick-action bar, not a tab controller, so no
screen state is swapped or lost.

The widget takes callbacks (`onSafeRouting`, `onNearestSafeSpot`, `onGuardianMode`,
`onReportIncident`) rather than performing navigation itself, so it stays testable and
has no dependency on `MapScreen` internals.

The existing `Drawer` stays, holding secondary destinations: Safety Map, **Contribute**
(new), **Download Offline Maps** (new), Settings, Sign out. Drawer entries that duplicate
bottom-bar items are removed.

### C. Contribute (Yes/No Verification)

New screen: `lib/views/screens/contribute_screen.dart`, reached from the drawer.

**Behaviour** — shows up to 2 short yes/no questions generated from `SafeSpot`s near the
user that have no verification recorded in the last 30 days. Question templates:

- "Is *{spot name}* well-lit at night?"
- "Is *{spot name}* still open and operating?"

Each renders as a card with `Yes` / `No` pill buttons and a `1/2 answered` progress row,
matching the reference's badge/task-card style. When both are answered (or none are
available), the screen shows a thank-you state.

**Data** — new Drift table `safe_spot_verifications`:

| Column | Type |
|---|---|
| `id` | int, autoincrement PK |
| `spot_id` | text |
| `question` | text |
| `answer` | bool |
| `answered_at` | datetime |
| `synced` | bool, default false |

New `ContributeRepository` + `ContributeViewModel` follow the exact local-outbox → Supabase
pattern already used by `IncidentRepository`, including a `syncOnConnectivityRestore()`
hook wired in `main.dart` alongside the existing repos.

**Out of scope:** verification answers are stored and synced but do **not** feed the ONNX
safety-scoring model in this pass. Changing model inputs is a separate, larger change.

### D. Offline Maps

Add `flutter_map_tile_caching` (FMTC version compatible with `flutter_map ^7`).

- Initialize the FMTC backend in `main.dart` at startup, before `runApp`, wrapped in a
  try/catch consistent with the existing best-effort service inits — a caching failure
  must not block app launch.
- `MapScreen`'s `TileLayer` switches from the plain network provider to FMTC's caching
  tile provider, pointed at a single named store. No other map logic changes; markers,
  routes, and safety scoring already work offline via Drift/ONNX.
- New screen: `lib/views/screens/download_offline_maps_screen.dart` (drawer entry):
  - Map preview of the region to download (defaults to the current viewport)
  - Zoom-range selector, default 12–16
  - Estimated tile count and download size
  - "Download for Offline Use" primary button
  - Live progress bar during download, success checkmark state on completion
- **Error handling:** on connectivity loss mid-download, show a failure state with a
  "Retry" action. Tiles are cached individually, so a partial download is valid and a
  retry resumes rather than restarting from zero.

## Testing

- Widget test: `bottom_nav_bar` renders 4 labelled items and fires the correct callback per tap.
- Widget test: `ContributeScreen` renders pending questions, and answering Yes/No advances
  progress and records via the view model.
- Unit test: `ContributeRepository` writes a verification row and marks it unsynced when offline.
- Manual verification via `flutter run`: confirm the red/black/white theme renders across
  Map, Guardian, Incident, and Routing screens; confirm an offline download completes and
  those tiles still render in airplane mode.
- `IncidentViewModel` and safety-scoring logic are untouched, so their existing tests stay green.

## Non-Goals

- No migration to tab-based navigation; `MapScreen` stays the persistent home.
- No changes to the ONNX model, its inputs, or the safety-grid data.
- No user-submitted safe spots (only yes/no verification of existing ones).
- No redesign of the Supabase schema beyond adding the verification table.
