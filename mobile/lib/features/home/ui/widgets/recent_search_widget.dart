import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/application/provider/recent_searches_provider.dart';
import 'package:mobile/features/home/data/model/recent_search_model.dart';

class RecentSearchesWidget extends ConsumerWidget {
  final Function(String) onSearchTap;

  const RecentSearchesWidget({
    super.key,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: AppColors.primary,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _showClearDialog(context, ref);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: recentSearches.map((search) {
              return _buildRecentSearchChip(search, isDark, ref);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchChip(RecentSearch search, bool isDark, WidgetRef ref) {
    return GestureDetector(
      onTap: () => onSearchTap(search.query),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 14.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              search.query,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            if (search.resultCount > 0) ...[
              SizedBox(width: 4.w),
              Text(
                '(${search.resultCount})',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () {
                ref.read(recentSearchesProvider.notifier).removeRecentSearch(search.query);
              },
              child: Icon(
                Icons.close_rounded,
                size: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Searches'),
        content: const Text('Are you sure you want to clear all recent searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recentSearchesProvider.notifier).clearAllRecentSearches();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recent searches cleared'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}