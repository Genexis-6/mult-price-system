import 'package:flutter/material.dart';
// import 'package:flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/platform_icons.dart';
import 'package:mobile/core/share/ui/widgets/welcome_section.dart';
import 'package:mobile/core/theme/app_color.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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
    final isCollapsed = scrollOffset > 100;
    
    return SliverAppBar(
      expandedHeight: 220.h,
      collapsedHeight: kToolbarHeight,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      elevation: isCollapsed ? 2 : 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxHeight > kToolbarHeight + 50;
          
          return Stack(
            children: [
              // Background that fades out when collapsed
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 1.0 : 0.0,
                child: CustomAppBarBackground(
                  isDark: isDark,
                  searchController: searchController,
                  onSearch: onSearch,
                  isLoading: isLoading,
                ),
              ),
              // Collapsed title that fades in when collapsed
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 0.0 : 1.0,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const StackedPlatformLogos(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
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
        // Main content - FIXED: Made scrollable or adjusted spacing
        SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnimatedPlatformIcons(),
                      const StackedPlatformLogos(),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  const WelcomeSection(),
                  SizedBox(height: 8.h),
                  const SmartTagline(),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}