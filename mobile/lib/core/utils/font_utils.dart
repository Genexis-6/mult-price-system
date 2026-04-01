import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontUtils {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        // Pre-load fonts to avoid platform channel issues
         GoogleFonts.spaceMonoTextTheme();
        _initialized = true;
      } catch (e) {
        debugPrint('Error loading fonts: $e');
        // Fallback to default fonts if loading fails
      }
    }
  }
  
  static TextStyle getPoppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
  
  static TextStyle getInter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}