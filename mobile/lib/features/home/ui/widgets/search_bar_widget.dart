import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 16.sp,
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textTertiary,
            size: 20.sp,
          ),
          suffixIcon: isLoading
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SizedBox(
                    height: 20.w,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onSearch,
                  icon: Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}