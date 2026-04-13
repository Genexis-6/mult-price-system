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
  final VoidCallback? onDelete;

  const PlatformTrackingCard({
    super.key,
    required this.product,
    required this.platformColor,
    required this.platformIcon,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCurrentPrice = product.currentPrice != null;

    return Container(
      constraints: BoxConstraints(
        minHeight: 170.h,
        maxHeight: 190.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Platform Badge Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: platformColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(platformIcon, color: platformColor, size: 16.sp),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomText(
                        product.productName,
                        type: TextType.bodyLarge,
                        color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14.sp,
                      ),
                    ),
                    _buildStatusBadge(isDark),
                  ],
                ),
                SizedBox(height: 12.h),
                // Price Info or Pending State
                if (hasCurrentPrice) ...[
                  _buildPriceInfo(isDark),
                  SizedBox(height: 10.h),
                  _buildProgressBar(isDark),
                ] else ...[
                  _buildPendingState(isDark),
                ],
                SizedBox(height: 8.h),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final status = product.status?.toLowerCase() ?? 'active';
    Color badgeColor;
    String badgeText;
    
    switch (status) {
      case 'triggered':
        badgeColor = Colors.green;
        badgeText = '🎯 Triggered';
        break;
      case 'active':
        badgeColor = Colors.orange;
        badgeText = '🔄 Active';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = status.toUpperCase();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: CustomText(
        badgeText,
        type: TextType.bodySmall,
        color: badgeColor,
        fontWeight: FontWeight.w600,
        fontSize: 10.sp,
      ),
    );
  }

  Widget _buildPendingState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Target Price',
                    type: TextType.bodySmall,
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    '₦${_formatPrice(product.targetPrice)}',
                    type: TextType.titleMedium,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    CustomText(
                      'PENDING',
                      type: TextType.bodySmall,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                size: 14.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: CustomText(
                  'Price check in progress. We\'ll notify you when the price is found.',
                  type: TextType.bodySmall,
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(bool isDark) {
    final priceDiff = product.currentPrice! - product.targetPrice;
    final isPriceLower = priceDiff <= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'Current',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
              fontSize: 10.sp,
            ),
            CustomText(
              '₦${_formatPrice(product.currentPrice!)}',
              type: TextType.titleSmall,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'Target',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
              fontSize: 10.sp,
            ),
            CustomText(
              '₦${_formatPrice(product.targetPrice)}',
              type: TextType.titleSmall,
              color: isPriceLower ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = (product.currentPrice! / product.targetPrice).clamp(0.0, 2.0);
    final isPriceLower = product.currentPrice! <= product.targetPrice;
    final percentage = ((1 - progress) * 100).abs();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isPriceLower ? Colors.green : platformColor,
            ),
            minHeight: 4.h,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              isPriceLower 
                  ? '${percentage.toStringAsFixed(0)}% below target'
                  : '${percentage.toStringAsFixed(0)}% above target',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
              fontSize: 10.sp,
            ),
            if (product.isTargetReached)
              Icon(Icons.check_circle, color: Colors.green, size: 14.sp),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: 6.h),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.textSecondary,
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              CustomText(
                _getTimeAgo(product.lastChecked),
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                fontSize: 10.sp,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete button
              if (onDelete != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.withOpacity(0.7),
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: platformColor,
                size: 12.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
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