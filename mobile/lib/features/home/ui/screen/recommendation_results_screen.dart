import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationResultsScreen extends ConsumerStatefulWidget {
  final List<Product> products;
  final String query;

  const RecommendationResultsScreen({
    super.key,
    required this.products,
    required this.query,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RecommendationResultsScreenState();
}

class _RecommendationResultsScreenState
    extends ConsumerState<RecommendationResultsScreen> {
  String _selectedSortBy = 'Recommended';
  bool _isGridView = false;

  final List<String> _sortOptions = [
    'Recommended',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Popularity',
  ];

  List<Product> get _sortedProducts {
    final products = List<Product>.from(widget.products);
    switch (_selectedSortBy) {
      case 'Price: Low to High':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Popularity':
        products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      default:
        products.sort((a, b) => a.rank.compareTo(b.rank));
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'Recommendations',
              type: TextType.titleLarge,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            CustomText(
              '${widget.products.length} results for "${widget.query}"',
              type: TextType.bodySmall,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Sort button
          Container(
            margin: EdgeInsets.only(right: 8.w),
            child: IconButton(
              onPressed: () => _showSortBottomSheet(isDark),
              icon: Icon(
                Icons.sort_rounded,
                color: AppColors.primary,
                size: 22.sp,
              ),
            ),
          ),
          // View toggle button
          Container(
            margin: EdgeInsets.only(right: 16.w),
            child: IconButton(
              onPressed: () => setState(() => _isGridView = !_isGridView),
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
      body: _isGridView ? _buildGridView(isDark) : _buildListView(isDark),
    );
  }

  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: _sortedProducts.length,
      itemBuilder: (context, index) {
        final product = _sortedProducts[index];
        return _buildProductCard(product, isDark);
      },
    );
  }

  Widget _buildGridView(bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.5,
      ),
      itemCount: _sortedProducts.length,
      itemBuilder: (context, index) {
        final product = _sortedProducts[index];
        return _buildGridProductCard(product, isDark);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isDark) {
    return GestureDetector(
      onTap: () => _launchUrl(product.productUrl),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${product.rank}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80.w,
                  height: 80.w,
                  color: AppColors.grey200,
                  child: Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80.w,
                  height: 80.w,
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

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Platform Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getPlatformColor(
                            product.sourcePlatform,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
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
                            size: 14.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ' (${product.reviewCount})',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
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

  Widget _buildGridProductCard(Product product, bool isDark) {
    return GestureDetector(
      onTap: () => _launchUrl(product.productUrl),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Badge
            Positioned(
              child: Container(
                margin: EdgeInsets.all(8.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '#${product.rank}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140.h,
                  color: AppColors.grey200,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140.h,
                  color: AppColors.grey200,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.grey400,
                    size: 40.sp,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
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
                          fontSize: 10.sp,
                          color: isDark
                              ? AppColors.grey400
                              : AppColors.textSecondary,
                        ),
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
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(
                        product.sourcePlatform,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      product.sourcePlatform.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: _getPlatformColor(product.sourcePlatform),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              ..._sortOptions.map(
                (option) => RadioListTile<String>(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                  ),
                  value: option,
                  groupValue: _selectedSortBy,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _selectedSortBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
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

Future<void> _launchUrl(String url) async {
  if (url.isEmpty) {
    CustomSnackbar.error(
      message: 'No URL available for this product',
      context: context,
    );
    return;
  }

  try {
    String finalUrl = url;
    if (!finalUrl.startsWith('http')) {
      finalUrl = 'https://$finalUrl';
    }

    final Uri uri = Uri.parse(finalUrl);

    // Always use browser-compatible mode
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      CustomSnackbar.error(
        message: 'Cannot open link: $finalUrl',
        // ignore: use_build_context_synchronously
        context: context,
      );
    }
  } catch (e) {
    print('Error launching URL: $e');
    CustomSnackbar.error(
      message: 'Unable to open the link',
      context: context,
    );
  }
}
}
