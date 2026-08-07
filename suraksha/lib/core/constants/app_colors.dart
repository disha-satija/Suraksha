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

  // ── Navigation ───────────────────────────────────────────────────────────
  static const Color inactiveNav  = Color(0xFF9E9E9E);

  /// Flat colour for a 0–1 safety score.
  static Color forScore(double score) {
    if (score >= 0.75) return safeGreen;
    if (score >= 0.50) return warningAmber;
    return dangerRed;
  }
}
