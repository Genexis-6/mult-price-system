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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7; // 70% of screen width

    return Container(
      width: cardWidth.clamp(280.w, 350.w), // Min 280, Max 350
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8.r,
            spreadRadius: 1.r,
            offset: Offset(0, 2.h),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Container
              _buildImageContainer(isDark),
              // Content
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Platform & Savings Row
                    _buildHeaderRow(isDark),
                    SizedBox(height: 6.h),
                    // Product Name
                    _buildProductName(isDark),
                    SizedBox(height: 6.h),
                    // Rating
                    _buildRatingRow(),
                    SizedBox(height: 8.h),
                    // Price Row
                    _buildPriceRow(isDark),
                    SizedBox(height: 8.h),
                    // Action Button
                    _buildActionButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(bool isDark) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: Image.network(
            deal.imageUrl,
            width: double.infinity,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 120.h,
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 32.sp,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              );
            },
          ),
        ),
        // Savings Badge
        Positioned(
          top: 8.h,
          right: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.discount_rounded, color: Colors.white, size: 12.sp),
                SizedBox(width: 3.w),
                CustomText(
                  '${deal.savingsPercentage.toStringAsFixed(0)}% OFF',
                  type: TextType.bodySmall,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: _getPlatformColor(deal.platform).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _getPlatformColor(deal.platform).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPlatformIcon(deal.platform),
                color: _getPlatformColor(deal.platform),
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              CustomText(
                deal.platform,
                type: TextType.bodySmall,
                color: _getPlatformColor(deal.platform),
                fontWeight: FontWeight.w600,
                fontSize: 10.sp,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: CustomText(
            'Best Deal',
            type: TextType.bodySmall,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 9.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildProductName(bool isDark) {
    return CustomText(
      deal.productName,
      type: TextType.bodyMedium,
      color: isDark ? AppColors.textLight : AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // height: 1.3,
      fontSize: 13.sp,
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < deal.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 14.sp,
          );
        }),
        SizedBox(width: 4.w),
        Flexible(
          child: CustomText(
            '(${deal.reviewCount})',
            type: TextType.bodySmall,
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Current Price',
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                fontSize: 10.sp,
              ),
              SizedBox(height: 2.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CustomText(
                  '₦${_formatPrice(deal.price)}',
                  type: TextType.titleLarge,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'You Save',
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                fontSize: 10.sp,
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomText(
                    '₦${_formatPrice(deal.savings)}',
                    type: TextType.bodyMedium,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 36.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16.sp),
                SizedBox(width: 6.w),
                CustomText(
                  'View Deal',
                  type: TextType.bodyMedium,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
                SizedBox(width: 6.w),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16.sp),
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
        return const Color(0xFFF68B1E);
      case 'konga':
        return const Color(0xFFED017F);
      case 'jiji':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
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