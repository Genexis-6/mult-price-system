import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/home/data/model/recent_search_model.dart';


class RecentSearchesChips extends StatelessWidget {
  final List<RecentSearch> searches;
  final Function(String) onSearchTap;

  const RecentSearchesChips({
    super.key,
    required this.searches,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: searches.map((search) {
              return GestureDetector(
                onTap: () => onSearchTap(search.query),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        search.query,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${search?.resultCount})',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}