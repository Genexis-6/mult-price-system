import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/data/model/news_model.dart';
import 'package:carousel_slider/carousel_slider.dart';

class NewsCarousel extends StatefulWidget {
  final List<News> newsList;
  final Function(News) onNewsTap;

  const NewsCarousel({
    super.key,
    required this.newsList,
    required this.onNewsTap,
  });

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Updates',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '30s',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          CarouselSlider(
            options: CarouselOptions(
              height: 100.h,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 30),
              enlargeCenterPage: true,
              viewportFraction: 0.92,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
            items: widget.newsList.map((news) {
              return GestureDetector(
                onTap: () => widget.onNewsTap(news),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: _getIconColor(news.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          _getIcon(news.type),
                          color: _getIconColor(news.type),
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              news.title,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              news.content,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _getTimeAgo(news.publishedAt),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.newsList.asMap().entries.map((entry) {
              return Container(
                width: _currentIndex == entry.key ? 20.w : 6.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.r),
                  color: _currentIndex == entry.key
                      ? AppColors.primary
                      : AppColors.grey300,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(NewsType type) {
    switch (type) {
      case NewsType.priceAlert:
        return AppColors.error;
      case NewsType.marketTrend:
        return AppColors.info;
      case NewsType.newProduct:
        return AppColors.success;
      case NewsType.tip:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIcon(NewsType type) {
    switch (type) {
      case NewsType.priceAlert:
        return Icons.local_offer_outlined;
      case NewsType.marketTrend:
        return Icons.trending_up;
      case NewsType.newProduct:
        return Icons.fiber_new;
      case NewsType.tip:
        return Icons.lightbulb_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}