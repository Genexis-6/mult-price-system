import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue-Grey Colors
  static const Color primaryBlueGrey = Color(0xFF546E7A);
  static const Color primaryLight = Color(0xFF819CA9);
  static const Color primaryDark = Color(0xFF29434E);
  
  // Secondary Accent Colors
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color accentLightTeal = Color(0xFF64D8CB);
  static const Color accentDarkTeal = Color(0xFF00766C);
  
  // Grey Scale
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF9E9E9E);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textDisabled = Color(0xFFB0BEC5);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlueGrey, primaryDark],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentTeal, accentDarkTeal],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, greyLight],
  );
}