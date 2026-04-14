import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/share/application/state/app_state.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
import 'package:mobile/features/settings/ui/widgets/device_section.dart';
import 'package:mobile/features/settings/ui/widgets/home_status_section.dart';
import 'package:mobile/features/settings/ui/widgets/profile_section.dart';
import 'package:mobile/features/settings/ui/widgets/settings_header.dart';
import 'package:mobile/features/settings/ui/widgets/settings_section_card.dart';
import 'package:mobile/features/settings/ui/widgets/tracking_state_section.dart';
// import 'package:mobile/features/settings/ui/widgets/tracking_stats_section.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appStateAsync = ref.watch(appStateProvider);
    final trackingNotifier = ref.read(priceTrackingProvider.notifier);
    final homeNotifier = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsHeader(isDark: isDark),
              SizedBox(height: 24.h),

              // Profile Section
              ProfileSection(
                isDark: isDark,
                cachedEmail: trackingNotifier.getCachedEmail(),
                hasEmail: trackingNotifier.hasCachedEmail(),
              ),
              SizedBox(height: 24.h),

              // Home Status Section
              HomeStatusSection(isDark: isDark),
              SizedBox(height: 24.h),

              // Device Section
              appStateAsync.when(
                data: (state) => DeviceSection(isDark: isDark, appState: state),
                loading: () => _buildLoadingSection(isDark),
                error: (_, __) => _buildErrorSection(isDark),
              ),
              SizedBox(height: 24.h),

              // Tracking Stats Section
              TrackingStatsSection(isDark: isDark),
              SizedBox(height: 24.h),

              // Storage Section
              _buildStorageSection(isDark, trackingNotifier),
              SizedBox(height: 24.h),

              // Actions Section
              _buildActionsSection(isDark, trackingNotifier, homeNotifier),
              SizedBox(height: 24.h),

              // Danger Zone
              _buildDangerZone(isDark, trackingNotifier, homeNotifier),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          CustomText(
            'Loading...',
            type: TextType.bodyMedium,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
          SizedBox(width: 8.w),
          CustomText(
            'Failed to load device info',
            type: TextType.bodyMedium,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection(
    bool isDark,
    PriceTrackingProvider trackingNotifier,
  ) {
    final hasEmail = trackingNotifier.hasCachedEmail();

    return SettingsSectionCard(
      isDark: isDark,
      title: 'Storage',
      icon: Icons.storage_outlined,
      children: [
        _buildInfoRow(
          icon: Icons.save_outlined,
          label: 'Cached Email',
          value: hasEmail ? 'Stored' : 'Not stored',
          isDark: isDark,
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildInfoRow(
          icon: Icons.history_outlined,
          label: 'Recent Searches',
          value: '3 items',
          isDark: isDark,
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildInfoRow(
          icon: Icons.data_usage_outlined,
          label: 'App Data',
          value: '2.4 MB',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
              SizedBox(height: 2.h),
              CustomText(
                value,
                type: TextType.bodyMedium,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionsSection(
    bool isDark,
    PriceTrackingProvider trackingNotifier,
    HomeProvider homeNotifier,
  ) {
    return SettingsSectionCard(
      isDark: isDark,
      title: 'Actions',
      icon: Icons.bolt_rounded,
      children: [
        _buildActionTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh Device Token',
          subtitle: 'Get a new FCM token',
          iconColor: Colors.blue,
          isDark: isDark,
          onTap: () async {
            await ref.read(appStateProvider.notifier).refreshDeviceToken();
            CustomSnackbar.success(
              context: context,
              message: 'Device token refreshed',
            );
          },
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildActionTile(
          icon: Icons.sync_rounded,
          title: 'Reconnect WebSocket',
          subtitle: 'Reconnect to real-time updates',
          iconColor: Colors.purple,
          isDark: isDark,
          onTap: () {
            trackingNotifier.reconnectWebSocket();
            CustomSnackbar.success(
              context: context,
              message: 'WebSocket reconnected',
            );
          },
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildActionTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh Tracking Data',
          subtitle: 'Fetch latest price alerts',
          iconColor: Colors.green,
          isDark: isDark,
          onTap: () async {
            await trackingNotifier.refreshData();
            CustomSnackbar.success(
              context: context,
              message: 'Tracking data refreshed',
            );
          },
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildActionTile(
          icon: Icons.search_off_rounded,
          title: 'Clear Search History',
          subtitle: 'Remove all recent searches',
          iconColor: Colors.teal,
          isDark: isDark,
          onTap: () => _showClearSearchDialog(),
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildActionTile(
          icon: Icons.cancel_outlined,
          title: 'Cancel Running Task',
          subtitle: 'Stop current search task',
          iconColor: Colors.orange,
          isDark: isDark,
          onTap: () async {
            await homeNotifier.cancelTask();
            CustomSnackbar.success(
              context: context,
              message: 'Task cancelled',
            );
          },
        ),
        Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
        _buildActionTile(
          icon: Icons.delete_sweep_rounded,
          title: 'Clear Cached Email',
          subtitle: 'Remove stored email',
          iconColor: Colors.orange,
          isDark: isDark,
          onTap: () => _showClearEmailDialog(trackingNotifier),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: iconColor, size: 18.sp),
      ),
      title: CustomText(
        title,
        type: TextType.bodyMedium,
        color: titleColor ?? (isDark ? AppColors.textLight : AppColors.textPrimary),
      ),
      subtitle: CustomText(
        subtitle,
        type: TextType.bodySmall,
        color: AppColors.textSecondary,
        fontSize: 11.sp,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.textSecondary,
        size: 14.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDangerZone(
    bool isDark,
    PriceTrackingProvider trackingNotifier,
    HomeProvider homeNotifier,
  ) {
    return SettingsSectionCard(
      isDark: isDark,
      title: 'Danger Zone',
      icon: Icons.warning_rounded,
      borderColor: Colors.red.withOpacity(0.5),
      children: [
        _buildActionTile(
          icon: Icons.restart_alt_rounded,
          title: 'Reset App State',
          subtitle: 'Clear all app data and restart',
          iconColor: Colors.red,
          titleColor: Colors.red,
          isDark: isDark,
          onTap: () => _showResetDialog(trackingNotifier, homeNotifier),
        ),
      ],
    );
  }

  void _showClearEmailDialog(PriceTrackingProvider notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const CustomText('Clear Cached Email?'),
        content: const CustomText(
          'This will remove your stored email. You\'ll need to enter it again for new alerts.',
          type: TextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(
              'Cancel',
              color: AppColors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () async {
              await notifier.clearCachedEmail();
              if (mounted) {
                Navigator.pop(context);
                CustomSnackbar.success(
                  context: context,
                  message: 'Cached email cleared',
                );
                setState(() {});
              }
            },
            child: CustomText(
              'Clear',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const CustomText('Clear Search History?'),
        content: const CustomText(
          'This will remove all your recent searches. This action cannot be undone.',
          type: TextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(
              'Cancel',
              color: AppColors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Clear search history logic here
              Navigator.pop(context);
              CustomSnackbar.success(
                context: context,
                message: 'Search history cleared',
              );
              setState(() {});
            },
            child: CustomText(
              'Clear',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(PriceTrackingProvider trackingNotifier, HomeProvider homeNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 10.w),
            const CustomText('Reset App State?'),
          ],
        ),
        content: const CustomText(
          'This will reset all app data including cached email, search history, and device registration. This action cannot be undone.',
          type: TextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(
              'Cancel',
              color: AppColors.textSecondary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: TextButton(
              onPressed: () async {
                final appNotifier = ref.read(appStateProvider.notifier);
                
                await trackingNotifier.clearCachedEmail();
                await homeNotifier.cancelTask();
                appNotifier.resetState();
                
                if (mounted) {
                  Navigator.pop(context);
                  CustomSnackbar.success(
                    context: context,
                    message: 'App state reset',
                  );
                  setState(() {});
                }
              },
              child: const CustomText(
                'Reset',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}