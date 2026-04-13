import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';

class PlatformTrackingCard extends StatelessWidget {
  final TrackedProduct product;
  final Color platformColor;
  final IconData platformIcon;
  final VoidCallback onTap;

  const PlatformTrackingCard({
    super.key,
    required this.product,
    required this.platformColor,
    required this.platformIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.surfaceDark, AppColors.surfaceDark.withOpacity(0.8)]
              : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: platformColor.withOpacity(0.1),
            blurRadius: 8.r,
            spreadRadius: 1.r,
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildProductImage(),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            product.productName,
                            type: TextType.bodyLarge,
                            color: isDark ? AppColors.textLight : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(platformIcon, color: platformColor, size: 14.sp),
                              SizedBox(width: 4.w),
                              CustomText(
                                product.platform.toUpperCase(),
                                type: TextType.bodySmall,
                                color: platformColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildPriceInfo(isDark),
                SizedBox(height: 8.h),
                _buildProgressBar(isDark),
                SizedBox(height: 8.h),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: platformColor.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: platformColor.withOpacity(0.1),
              child: Icon(
                Icons.image_not_supported,
                color: platformColor,
                size: 24.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceInfo(bool isDark) {
    final priceDiff = product.currentPrice - product.targetPrice;
    final isPriceLower = priceDiff <= 0;
    final diffPercentage = (priceDiff.abs() / product.targetPrice) * 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'Current',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
            CustomText(
              '₦${product.currentPrice.toStringAsFixed(0)}',
              type: TextType.titleMedium,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomText(
              'Target',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
            CustomText(
              '₦${product.targetPrice.toStringAsFixed(0)}',
              type: TextType.titleMedium,
              color: isPriceLower ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = (product.currentPrice / product.targetPrice).clamp(0.0, 2.0);
    final isPriceLower = product.currentPrice <= product.targetPrice;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isPriceLower ? Colors.green : platformColor,
            ),
            minHeight: 6.h,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              '${(progress * 100).toStringAsFixed(0)}% of target',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
            if (product.isTargetReached)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: CustomText(
                  'Target Reached!',
                  type: TextType.bodySmall,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.textSecondary,
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              CustomText(
                'Updated ${_getTimeAgo(product.lastChecked)}',
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: platformColor,
            size: 14.sp,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}