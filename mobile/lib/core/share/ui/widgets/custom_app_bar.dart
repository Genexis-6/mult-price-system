import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/platform_icons.dart';
import 'package:mobile/core/share/ui/widgets/welcome_section.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/gen/assets.gen.dart';

class CustomAppBar extends StatelessWidget {
  final bool isDark;
  final double scrollOffset;
  final VoidCallback onSearch;
  final TextEditingController searchController;
  final bool isLoading;

  const CustomAppBar({
    super.key,
    required this.isDark,
    required this.scrollOffset,
    required this.onSearch,
    required this.searchController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.h,
      collapsedHeight: 50.h,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      elevation: scrollOffset > 100 ? 2 : 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: EdgeInsets.zero,
        title: CollapsedAppBarTitle(scrollOffset: scrollOffset),
        background: CustomAppBarBackground(
          isDark: isDark,
          searchController: searchController,
          onSearch: onSearch,
          isLoading: isLoading,
        ),
      ),
    );
  }
}

class CollapsedAppBarTitle extends StatelessWidget {
  final double scrollOffset;

  const CollapsedAppBarTitle({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: scrollOffset > 100 ? 1.0 : 0.0,
      child: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: Text(
                'MulaSearch',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomAppBarBackground extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final bool isLoading;

  const CustomAppBarBackground({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                    ]
                  : [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                      const Color(0xFFf093fb),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Decorative circles
        ...List.generate(3, (index) {
          return Positioned(
            left: 20.w * (index + 1),
            top: 30.h * (index + 1),
            child: Container(
              width: 100.w - (index * 20.w),
              height: 100.w - (index * 20.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          );
        }),
        // Main content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedPlatformIcons(),
                    const StackedPlatformLogos(),
                  ],
                ),
                SizedBox(height: 20.h),
                const WelcomeSection(),
                SizedBox(height: 12.h),
                const SmartTagline(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}