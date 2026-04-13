import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
import 'package:mobile/features/track/ui/widgets/platform_tracking_cards.dart';
import 'package:mobile/features/track/ui/widgets/delete_alert_dialog.dart';

class CancelledSection extends ConsumerWidget {
  final List<PlatformTracking> cancelledPlatforms;
  final bool isDark;

  const CancelledSection({
    super.key,
    required this.cancelledPlatforms,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cancelledPlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    // Flatten all cancelled products
    final allCancelledProducts = cancelledPlatforms
        .expand((platform) => platform.products)
        .toList();

    if (allCancelledProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: _buildSectionHeader(allCancelledProducts.length),
        ),
        SizedBox(
          height: 230.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: allCancelledProducts.length,
            itemBuilder: (context, index) {
              final product = allCancelledProducts[index];
              // Find the platform color for this product
              final platform = cancelledPlatforms.firstWhere(
                (p) => p.products.contains(product),
                orElse: () => cancelledPlatforms.first,
              );
              
              return Container(
                width: 280.w,
                margin: EdgeInsets.only(right: 12.w, bottom: 8.h, top: 4.h),
                child: Opacity(
                  opacity: 0.7,
                  child: PlatformTrackingCard(
                    product: product,
                    platformColor: Colors.grey,
                    platformIcon: Icons.cancel_outlined,
                    onTap: () {
                      // Show details or do nothing for cancelled
                    },
                    onDelete: null, // No delete for already cancelled
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: Colors.grey,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'CANCELLED',
                  type: TextType.titleMedium,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  '$count cancelled alerts',
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
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.archive_outlined,
                color: Colors.grey,
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              CustomText(
                'Archived',
                type: TextType.bodySmall,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}