import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD81B60);       // deep pink
  static const Color primaryLight = Color(0xFFFF5C8D);
  static const Color primaryDark = Color(0xFF880E4F);

  static const Color safeGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFF44336);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color subtitle = Color(0xFF757575);

  static const Color onlineIndicator = Color(0xFF4CAF50);
  static const Color offlineCachedIndicator = Color(0xFFFF9800);
  static const Color offlineStaleIndicator = Color(0xFFF44336);

  /// Returns color for a given 0–1 safety score.
  static Color forScore(double score) {
    if (score >= 0.75) return safeGreen;
    if (score >= 0.50) return warningAmber;
    return dangerRed;
  }
}
