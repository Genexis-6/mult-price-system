import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/theme/text_theme.dart';

class CustomButtons {
  // Primary Button
  static Widget primaryButton({
    required VoidCallback onPressed,
    required String text,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    IconData? icon,
    Gradient? gradient,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        text,
                        style: AppTextTheme.lightTextTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  // Secondary Button (Outlined)
  static Widget secondaryButton({
    required VoidCallback onPressed,
    required String text,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    IconData? icon,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: AppTextTheme.lightTextTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  // Text Button
  static Widget textButton({
    required VoidCallback onPressed,
    required String text,
    bool isLoading = false,
    Color? textColor,
  }) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? AppColors.primary,
                ),
              ),
            )
          : Text(
              text,
              style: AppTextTheme.lightTextTheme.labelLarge?.copyWith(
                color: textColor ?? AppColors.primary,
              ),
            ),
    );
  }
  
  // Icon Button
  static Widget iconButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor,
    double size = 48,
    double iconSize = 24,
  }) {
    return Container(
      height: size.h,
      width: size.w,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor ?? AppColors.primary),
        iconSize: iconSize.sp,
      ),
    );
  }
  
  // Floating Action Button
  static Widget floatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    bool isExtended = false,
    String? label,
  }) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: AppTextTheme.lightTextTheme.labelMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      );
    }
    
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      child: Icon(icon, color: Colors.white),
    );
  }
  
  // Social Media Button
  static Widget socialButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.grey300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: backgroundColor ?? AppColors.primary, size: 20.sp),
          SizedBox(width: 12.w),
          Text(
            text,
            style: AppTextTheme.lightTextTheme.labelMedium?.copyWith(
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}