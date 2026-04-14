import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/application/state/app_state.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/settings/ui/widgets/settings_section_card.dart';

class DeviceSection extends StatelessWidget {
  final bool isDark;
  final AppState appState;

  const DeviceSection({
    super.key,
    required this.isDark,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      isDark: isDark,
      title: 'Device & Notifications',
      icon: Icons.devices_outlined,
      children: [
        if (appState.isRegistered) ...[
          _buildInfoRow(
            icon: Icons.phone_android_outlined,
            label: 'Device ID',
            value: '#${appState.deviceId}',
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.notifications_active_outlined,
            label: 'FCM Token',
            value: _formatToken(appState.fcmToken),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 8.sp),
                  SizedBox(width: 4.w),
                  CustomText(
                    'Active',
                    type: TextType.bodySmall,
                    color: Colors.green,
                    fontSize: 10.sp,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: CustomText(
              'Push Notifications',
              type: TextType.bodyMedium,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            subtitle: CustomText(
              'Receive alerts when prices drop',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
            value: true,
            onChanged: (value) {
              CustomSnackbar.info(
                context: context,
                message: 'Notification settings coming soon',
              );
            },
          ),
        ] else ...[
          _buildInfoRow(
            icon: Icons.error_outline,
            label: 'Status',
            value: 'Device not registered',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
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
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  String _formatToken(String? token) {
    if (token == null || token.length < 12) return 'Not available';
    return '${token.substring(0, 12)}...';
  }
}