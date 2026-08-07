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
