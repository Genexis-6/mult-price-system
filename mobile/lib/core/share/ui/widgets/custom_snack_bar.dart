import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/theme/text_theme.dart';


class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    SnackBarAction? action,
    bool showIcon = true,
  }) {
    // Remove any existing snackbars
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    // Get color based on type
    final Color backgroundColor = _getBackgroundColor(type);
    final IconData icon = _getIcon(type);
    final Color iconColor = _getIconColor(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showIcon) ...[
              Icon(icon, color: iconColor, size: 20.sp),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextTheme.lightTextTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: duration,
        action: action ??
            (actionLabel != null && onAction != null
                ? SnackBarAction(
                    label: actionLabel,
                    textColor: Colors.white,
                    onPressed: onAction,
                  )
                : null),
      ),
    );
  }
  
  // Success snackbar
  static void success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.success,
      duration: duration,
    );
  }
  
  // Error snackbar
  static void error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
    );
  }
  
  // Warning snackbar
  static void warning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.warning,
      duration: duration,
    );
  }
  
  // Info snackbar
  static void info({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: SnackbarType.info,
      duration: duration,
    );
  }
  
  static Color _getBackgroundColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.success;
      case SnackbarType.error:
        return AppColors.error;
      case SnackbarType.warning:
        return AppColors.warning;
      case SnackbarType.info:
        return AppColors.info;
      default:
        return AppColors.primaryBlueGrey;
    }
  }
  
  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.warning:
        return Icons.warning_amber_outlined;
      case SnackbarType.info:
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }
  
  static Color _getIconColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.white;
      case SnackbarType.error:
        return Colors.white;
      case SnackbarType.warning:
        return Colors.white;
      case SnackbarType.info:
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}

enum SnackbarType { success, error, warning, info }