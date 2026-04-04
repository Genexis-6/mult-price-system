import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextTheme {
  static TextTheme get lightTextTheme {
    try {
      return TextTheme(
        displayLarge: GoogleFonts.googleSansFlex(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.googleSansFlex(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.googleSansFlex(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.googleSansFlex(
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.googleSansFlex(
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.googleSansFlex(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.googleSansFlex(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.googleSansFlex(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.googleSansFlex(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.googleSansFlex(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.googleSansFlex(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: GoogleFonts.googleSansFlex(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.googleSansFlex(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.googleSansFlex(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.googleSansFlex(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    } catch (e) {
      // Fallback to system fonts if Google Fonts fails
      debugPrint('Google Fonts error: $e, using system fonts');
      return _getSystemFontTextTheme();
    }
  }

  static TextTheme _getSystemFontTextTheme() {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
        letterSpacing: -0.5,
      ),
      displayMedium: const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
        letterSpacing: -0.5,
      ),
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      titleSmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        fontFamily: 'Roboto',
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'Roboto',
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        fontFamily: 'Roboto',
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
    );
  }

  static TextTheme get darkTextTheme {
    // Similarly, implement dark theme with fallback
    final lightTheme = lightTextTheme;
    return lightTheme.copyWith(
      displayLarge: lightTheme.displayLarge?.copyWith(color: Colors.white),
      displayMedium: lightTheme.displayMedium?.copyWith(color: Colors.white),
      displaySmall: lightTheme.displaySmall?.copyWith(color: Colors.white),
      headlineLarge: lightTheme.headlineLarge?.copyWith(color: Colors.white),
      headlineMedium: lightTheme.headlineMedium?.copyWith(color: Colors.white),
      headlineSmall: lightTheme.headlineSmall?.copyWith(color: Colors.white),
      titleLarge: lightTheme.titleLarge?.copyWith(color: Colors.white),
      titleMedium: lightTheme.titleMedium?.copyWith(color: Colors.white),
      titleSmall: lightTheme.titleSmall?.copyWith(color: Colors.white70),
      bodyLarge: lightTheme.bodyLarge?.copyWith(color: Colors.white),
      bodyMedium: lightTheme.bodyMedium?.copyWith(color: Colors.white),
      bodySmall: lightTheme.bodySmall?.copyWith(color: Colors.white70),
      labelLarge: lightTheme.labelLarge?.copyWith(color: Colors.white),
      labelMedium: lightTheme.labelMedium?.copyWith(color: Colors.white70),
      labelSmall: lightTheme.labelSmall?.copyWith(color: Colors.white54),
    );
  }
}
