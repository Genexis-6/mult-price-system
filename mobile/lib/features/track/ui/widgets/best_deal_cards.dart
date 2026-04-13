import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';

class BestDealCard extends StatelessWidget {
  final BestDeal deal;
  final VoidCallback onTap;

  const BestDealCard({
    super.key,
    required this.deal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPlatformColor(deal.platform).withOpacity(0.15),
            isDark ? AppColors.surfaceDark : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getPlatformColor(deal.platform).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with platform and savings badge
                _buildHeader(isDark),
                SizedBox(height: 12.h),
                // Product name
                _buildProductName(isDark),
                SizedBox(height: 12.h),
                // Price comparison
                _buildPriceComparison(isDark),
                SizedBox(height: 12.h),
                // Savings highlight
                _buildSavingsHighlight(isDark),
                SizedBox(height: 12.h),
                // Action button
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: _getPlatformColor(deal.platform).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getPlatformIcon(deal.platform),
                color: _getPlatformColor(deal.platform),
                size: 16.sp,
              ),
            ),
            SizedBox(width: 8.w),
            CustomText(
              deal.platform.toUpperCase(),
              type: TextType.bodySmall,
              color: _getPlatformColor(deal.platform),
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade700],
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded, color: Colors.white, size: 14.sp),
              SizedBox(width: 4.w),
              CustomText(
                'TRIGGERED',
                type: TextType.bodySmall,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductName(bool isDark) {
    return CustomText(
      deal.productName,
      type: TextType.bodyLarge,
      color: isDark ? AppColors.textLight : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      height: 1.3,
      fontSize: 15.sp,
    );
  }

  Widget _buildPriceComparison(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Target Price',
                  type: TextType.bodySmall,
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  '₦${_formatPrice(deal.targetPrice)}',
                  type: TextType.titleMedium,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  decoration: TextDecoration.lineThrough,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 20.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  'Current Price',
                  type: TextType.bodySmall,
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  '₦${_formatPrice(deal.price)}',
                  type: TextType.titleLarge,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsHighlight(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.savings_rounded, color: Colors.green, size: 20.sp),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'You Save',
                    type: TextType.bodySmall,
                    color: Colors.green,
                    fontSize: 11.sp,
                  ),
                  CustomText(
                    '₦${_formatPrice(deal.savings)}',
                    type: TextType.titleMedium,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: CustomText(
              '${deal.savingsPercentage.toStringAsFixed(0)}% OFF',
              type: TextType.bodySmall,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 40.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18.sp),
                SizedBox(width: 8.w),
                CustomText(
                  'Buy Now at Best Price',
                  type: TextType.bodyMedium,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ],
            ),
          ),
        ),
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

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return const Color(0xFFFF6B00);
      case 'konga':
        return const Color(0xFFFF0066);
      case 'jiji':
        return const Color(0xFF00D084);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return Icons.shopping_bag_rounded;
      case 'konga':
        return Icons.store_rounded;
      case 'jiji':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }
}