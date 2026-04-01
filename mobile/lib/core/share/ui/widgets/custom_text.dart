import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_color.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextType type;
  final Color? color;
  final Color? lightColor;
  final Color? darkColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final double? fontSize;
  final TextDecoration? decoration;
  final bool isColorResponsive;
  
  const CustomText(
    this.text, {
    super.key,
    this.type = TextType.bodyMedium,
    this.color,
    this.lightColor,
    this.darkColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.fontSize,
    this.decoration,
    this.isColorResponsive = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      text,
      style: _getTextStyle(context, isDarkMode),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  
  TextStyle _getTextStyle(BuildContext context, bool isDarkMode) {
    TextStyle? baseStyle;
    
    switch (type) {
      case TextType.displayLarge:
        baseStyle = GoogleFonts.spaceMono(fontSize: 57, fontWeight: FontWeight.bold);
        break;
      case TextType.displayMedium:
        baseStyle = GoogleFonts.spaceMono(fontSize: 45, fontWeight: FontWeight.bold);
        break;
      case TextType.displaySmall:
        baseStyle = GoogleFonts.spaceMono(fontSize: 36, fontWeight: FontWeight.bold);
        break;
      case TextType.headlineLarge:
        baseStyle = GoogleFonts.spaceMono(fontSize: 32, fontWeight: FontWeight.w600);
        break;
      case TextType.headlineMedium:
        baseStyle = GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.w600);
        break;
      case TextType.headlineSmall:
        baseStyle = GoogleFonts.spaceMono(fontSize: 24, fontWeight: FontWeight.w600);
        break;
      case TextType.titleLarge:
        baseStyle = GoogleFonts.spaceMono(fontSize: 22, fontWeight: FontWeight.w600);
        break;
      case TextType.titleMedium:
        baseStyle = GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w500);
        break;
      case TextType.titleSmall:
        baseStyle = GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w500);
        break;
      case TextType.bodyLarge:
        baseStyle = GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.normal);
        break;
      case TextType.bodyMedium:
        baseStyle = GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.normal);
        break;
      case TextType.bodySmall:
        baseStyle = GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.normal);
        break;
      case TextType.labelLarge:
        baseStyle = GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w600);
        break;
      case TextType.labelMedium:
        baseStyle = GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w500);
        break;
      case TextType.labelSmall:
        baseStyle = GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w500);
        break;
    }
    
    // Determine the final color
    Color finalColor;
    
    if (color != null) {
      // If explicit color is provided, use it regardless of theme
      finalColor = color!;
    } else if (isColorResponsive) {
      // Use theme-aware colors
      if (isDarkMode) {
        finalColor = darkColor ?? _getDarkModeColorForType();
      } else {
        finalColor = lightColor ?? _getLightModeColorForType();
      }
    } else {
      // Use default colors without theme awareness
      finalColor = _getDefaultColorForType();
    }
    
    return baseStyle?.copyWith(
      color: finalColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      decoration: decoration,
    ) ?? TextStyle(color: finalColor);
  }
  
  Color _getLightModeColorForType() {
    switch (type) {
      case TextType.displayLarge:
      case TextType.displayMedium:
      case TextType.displaySmall:
      case TextType.headlineLarge:
      case TextType.headlineMedium:
      case TextType.headlineSmall:
      case TextType.titleLarge:
      case TextType.titleMedium:
        return AppColors.textPrimary;
      case TextType.titleSmall:
      case TextType.bodyLarge:
      case TextType.bodyMedium:
        return AppColors.textPrimary;
      case TextType.bodySmall:
      case TextType.labelLarge:
      case TextType.labelMedium:
      case TextType.labelSmall:
        return AppColors.textSecondary;
      default:
        return AppColors.textPrimary;
    }
  }
  
  Color _getDarkModeColorForType() {
    switch (type) {
      case TextType.displayLarge:
      case TextType.displayMedium:
      case TextType.displaySmall:
      case TextType.headlineLarge:
      case TextType.headlineMedium:
      case TextType.headlineSmall:
      case TextType.titleLarge:
      case TextType.titleMedium:
        return AppColors.textLight;
      case TextType.titleSmall:
      case TextType.bodyLarge:
      case TextType.bodyMedium:
        return AppColors.textLight;
      case TextType.bodySmall:
      case TextType.labelLarge:
      case TextType.labelMedium:
      case TextType.labelSmall:
        return AppColors.greyLight;
      default:
        return AppColors.textLight;
    }
  }
  
  Color _getDefaultColorForType() {
    switch (type) {
      case TextType.bodySmall:
      case TextType.labelMedium:
      case TextType.labelSmall:
        return AppColors.textSecondary;
      default:
        return AppColors.textPrimary;
    }
  }
}

enum TextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}