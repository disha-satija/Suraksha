import 'package:flutter/material.dart';

/// Notion-inspired flat colour palette.
/// All logic that references AppColors continues to work —
/// only the actual colour values change here.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF6940A5); // deep purple
  static const Color primaryLight = Color(0xFF9B72CF); // light purple
  static const Color primaryDark  = Color(0xFF4A2D7A); // darker purple

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color safeGreen    = Color(0xFF2D9B6F); // muted green
  static const Color warningAmber = Color(0xFFD9730D); // muted amber
  static const Color dangerRed    = Color(0xFFE03E3E); // muted red

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color background   = Color(0xFFFAFAFA); // off-white
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE5E5E5); // 1-px divider
  static const Color hoverBg      = Color(0xFFF5F5F5); // subtle hover

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color onSurface    = Color(0xFF1A1A1A); // near-black
  static const Color subtitle     = Color(0xFF6B6B6B); // secondary text
  static const Color hint         = Color(0xFFADADAD); // placeholder

  // ── Connectivity indicators ───────────────────────────────────────────────
  static const Color onlineIndicator          = Color(0xFF2D9B6F);
  static const Color offlineCachedIndicator   = Color(0xFFD9730D);
  static const Color offlineStaleIndicator    = Color(0xFFE03E3E);

  /// Flat colour for a 0–1 safety score.
  static Color forScore(double score) {
    if (score >= 0.75) return safeGreen;
    if (score >= 0.50) return warningAmber;
    return dangerRed;
  }
}
