import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/settings/ui/widgets/settings_section_card.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';
import 'package:mobile/features/track/application/state/price_tracking_state.dart';

class TrackingStatsSection extends ConsumerWidget {
  final bool isDark;

  const TrackingStatsSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(priceTrackingProvider);

    return SettingsSectionCard(
      isDark: isDark,
      title: 'Price Tracking Stats',
      icon: Icons.track_changes_rounded,
      children: [
        trackingState.when(
          data: (state) {
            if (state.isLoaded) {
              final loadedState = state.asLoaded!;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.notifications_active_rounded,
                      value: loadedState.activeAlerts.toString(),
                      label: 'Active',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_rounded,
                      value: loadedState.triggeredAlerts.toString(),
                      label: 'Triggered',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cancel_outlined,
                      value: loadedState.cancelledAlerts.toString(),
                      label: 'Cancelled',
                      color: Colors.grey,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            }
            return _buildEmptyStats(isDark);
          },
          loading: () => _buildLoadingStats(isDark),
          error: (_, __) => _buildEmptyStats(isDark),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
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
            fontSize: 10.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildSkeletonStatCard(isDark)),
        SizedBox(width: 12.w),
        Expanded(child: _buildSkeletonStatCard(isDark)),
        SizedBox(width: 12.w),
        Expanded(child: _buildSkeletonStatCard(isDark)),
      ],
    );
  }

  Widget _buildSkeletonStatCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 20.sp,
            height: 20.sp,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 30.w,
            height: 16.h,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Container(
            width: 40.w,
            height: 12.h,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: CustomText(
          'No tracking data available',
          type: TextType.bodyMedium,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}