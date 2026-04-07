import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/features/home/data/model/recommendation_model.dart';

class CompletedTaskCard extends StatelessWidget {
  final List<Product> products;
  final String query;
  final VoidCallback onDismiss;
  final Function(Product)? onProductTap;

  const CompletedTaskCard({
    super.key,
    required this.products,
    required this.onDismiss,
    this.onProductTap, required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasResults = products.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.success.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Completed! 🎉',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      hasResults
                          ? 'Found ${products.length} product recommendations'
                          : 'Your request has been processed successfully.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? AppColors.grey400 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.grey300.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Results preview
          if (hasResults) ...[
            ...products.take(3).map((product) => _buildProductPreview(product, isDark)),
            if (products.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Navigate to full results screen
                      context.push("/home/recommendations", extra: RecommendationModel(product: products, query: query));
                    },
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'View all ${products.length} recommendations',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductPreview(Product product, bool isDark) {
    return GestureDetector(
      onTap: () => onProductTap?.call(product),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image with caching
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60.w,
                  height: 60.w,
                  color: AppColors.grey200,
                  child: Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60.w,
                  height: 60.w,
                  color: AppColors.grey200,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.grey400,
                    size: 30.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Platform badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getPlatformColor(product.sourcePlatform).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          product.sourcePlatform.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: _getPlatformColor(product.sourcePlatform),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? AppColors.grey400 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        '₦${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Score: ${(product.recommendationScore * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return Colors.orange;
      case 'jiji':
        return Colors.green;
      case 'konga':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}