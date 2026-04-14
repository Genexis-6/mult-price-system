import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/settings/ui/widgets/settings_section_card.dart';

class ProfileSection extends StatelessWidget {
  final bool isDark;
  final String? cachedEmail;
  final bool hasEmail;

  const ProfileSection({
    super.key,
    required this.isDark,
    required this.cachedEmail,
    required this.hasEmail,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      isDark: isDark,
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      children: [
        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: hasEmail ? cachedEmail! : 'Not set',
          trailing: hasEmail
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: CustomText(
                    'Verified',
                    type: TextType.bodySmall,
                    color: Colors.green,
                    fontSize: 10.sp,
                  ),
                )
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: CustomText(
                    'Pending',
                    type: TextType.bodySmall,
                    color: Colors.orange,
                    fontSize: 10.sp,
                  ),
                ),
        ),
        if (hasEmail) ...[
          Divider(height: 16.h, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _formatDate(DateTime.now().subtract(const Duration(days: 7))),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}