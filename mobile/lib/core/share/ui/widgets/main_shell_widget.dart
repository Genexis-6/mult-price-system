import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/share/ui/widgets/splash_widget.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';
// import 'package:mobile/core/share/ui/widgets/splash_screen.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';
import 'package:mobile/features/home/application/state/home_state.dart';

class MainShellWidgets extends ConsumerStatefulWidget {
  const MainShellWidgets({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MainShellWidgetsState();
}

class _MainShellWidgetsState extends ConsumerState<MainShellWidgets> {
  int _currentIndex = 0;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Start initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeProvider();
    });
  }

  Future<void> _initializeHomeProvider() async {
    // This will trigger the build method of homeProvider
    // which checks for existing tasks
    await ref.read(homeProvider.future);
    
    // Give a minimum splash time for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = ref.watch(homeProvider);
    
    // Show splash screen while initializing or if explicitly showing
    if (_showSplash) {
      return SplashScreen(
        onSplashComplete: () {},
        duration: const Duration(seconds: 2),
      );
    }
    
    // Check if we should show reconnecting banner based on home state
    final showReconnectingBanner = homeState.maybeWhen(
      data: (state) => state.isReconnecting,
      orElse: () => false,
    );
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.child,
          
          // Reconnecting banner if needed
          if (showReconnectingBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                color: Colors.orange,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Reconnecting to task...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            AppRouteUtlis.goScreen(context, index: index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          elevation: 2,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.grey500 : AppColors.grey600,
          showUnselectedLabels: true,
          items: AppRouteUtlis.routes.map((tab) {
            return BottomNavigationBarItem(
              icon: FaIcon(tab.icon, size: 22.sp),
              activeIcon: FaIcon(tab.icon, size: 24.sp),
              label: tab.name,
            );
          }).toList(),
        ),
      ),
    );
  }
}