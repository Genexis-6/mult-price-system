import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
import 'package:mobile/features/track/ui/widgets/platform_tracking_cards.dart';
import 'package:mobile/features/track/ui/widgets/delete_alert_dialog.dart';
import 'package:mobile/features/track/ui/widgets/update_price_dialog.dart';

class PlatformSection extends ConsumerWidget {
  final PlatformTracking platform;
  final bool isDark;

  const PlatformSection({
    super.key,
    required this.platform,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: _buildSectionHeader(),
        ),
        if (platform.products.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 230.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: platform.products.length,
              itemBuilder: (context, index) {
                final product = platform.products[index];
                return Container(
                  width: 280.w,
                  margin: EdgeInsets.only(right: 12.w, bottom: 8.h, top: 4.h),
                  child: PlatformTrackingCard(
                    product: product,
                    platformColor: platform.platformColor,
                    platformIcon: platform.platformIcon,
                    onEdit: () => _showEditDialog(context, product),
                    onTap: () {
                      // Navigate to product details
                    },
                    onDelete: () => _showDeleteDialog(context, product),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _showEditDialog(BuildContext context, TrackedProduct product) {
    showDialog(
      context: context,
      builder: (context) => UpdateAlertDialog(product: product),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: platform.platformColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                platform.platformIcon,
                color: platform.platformColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  platform.platform.toUpperCase(),
                  type: TextType.titleMedium,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  '${platform.products.length} products tracked',
                  type: TextType.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: platform.platformColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: platform.platformColor,
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              CustomText(
                '${platform.activeAlerts} active',
                type: TextType.bodySmall,
                color: platform.platformColor,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withOpacity(0.3)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 32.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            CustomText(
              'No products tracked on ${platform.platform}',
              type: TextType.bodyMedium,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TrackedProduct product) {
    showDialog(
      context: context,
      builder: (context) => DeleteAlertDialog(
        alertId: int.parse(product.id),
        productName: product.productName,
      ),
    );
  }
}
