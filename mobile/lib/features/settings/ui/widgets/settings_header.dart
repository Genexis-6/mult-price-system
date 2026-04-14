import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/theme/app_color.dart';

class SettingsHeader extends StatelessWidget {
  final bool isDark;

  const SettingsHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'Settings',
              type: TextType.headlineSmall,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            CustomText(
              'Manage your preferences',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}