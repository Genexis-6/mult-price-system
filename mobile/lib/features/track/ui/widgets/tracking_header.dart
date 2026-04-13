import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';

class TrackingHeader extends StatelessWidget {
  final String userEmail;
  final int totalTrackedProducts;
  final VoidCallback onAddAlert;

  const TrackingHeader({
    super.key,
    required this.userEmail,
    required this.totalTrackedProducts,
    required this.onAddAlert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(0.15), Colors.transparent]
              : [AppColors.primary.withOpacity(0.08), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Welcome back,',
                    type: TextType.bodyMedium,
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    userEmail.split('@')[0],
                    type: TextType.headlineSmall,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              _buildAddButton(context, isDark),
            ],
          ),
          SizedBox(height: 20.h),
          _buildStatsCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAddAlert,
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              Icons.add_alert_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surfaceDark.withOpacity(0.5)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark 
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.track_changes_rounded,
              value: totalTrackedProducts.toString(),
              label: 'Tracking',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.notifications_active_rounded,
              value: '3',
              label: 'Active Alerts',
              color: Colors.orange,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.savings_rounded,
              value: '₦245K',
              label: 'Potential Savings',
              color: Colors.green,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(height: 8.h),
        CustomText(
          value,
          type: TextType.titleMedium,
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 2.h),
        CustomText(
          label,
          type: TextType.bodySmall,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}