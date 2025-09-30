import 'package:flutter/material.dart';

/// COLOR CONSTANTS
class AppColors {
  static const Color primary = Color(0xFF51B4E8);
  static const Color secondary = Color(0xFFFF8800);
  static const Color accent = Color(0xFF3A8FB7);
  static const Color success = Color(0xFF48C78E);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFC107);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF6D7684);
}


/// TEXT STYLE CONSTANTS
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    fontSize: 30,
    color: AppColors.textPrimary,
  );

  static const TextStyle subHeading = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    color: AppColors.textPrimary,
  );

  static const TextStyle midFont = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle regular = TextStyle(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle notificationText = TextStyle(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    letterSpacing: -0.08,
    height: 18 / 13,
    color: AppColors.textSecondary,
  );
}