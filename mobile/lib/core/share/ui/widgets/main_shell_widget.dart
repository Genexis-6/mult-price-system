
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';

class MainShellWidgets extends StatefulWidget {
  const MainShellWidgets({super.key});

  @override
  State<MainShellWidgets> createState() => _MainShellWidgetsState();
}

class _MainShellWidgetsState extends State<MainShellWidgets> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final NotchBottomBarController _controller;
  int _currentIndex = 0;
  
  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _controller = NotchBottomBarController(index: 0);
    
    // Initialize fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> bottomBarPages = AppRouteUtlis.routes
        .map((route) => route.screen)
        .toList();

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _controller.index = index;
          });
          // Trigger fade animation
          _fadeController.reset();
          _fadeController.forward();
        },
        children: bottomBarPages.asMap().entries.map((entry) {
          return _buildPageWithAnimation(entry.value, entry.key);
        }).toList(),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPageWithAnimation(Widget page, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        // Only animate the current page
        if (_currentIndex == index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          );
        }
        return child ?? const SizedBox.shrink();
      },
      child: page,
    );
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedNotchBottomBar(
      notchBottomBarController: _controller,
      color: Theme.of(context).colorScheme.surface,
      showLabel: true,
      textOverflow: TextOverflow.visible,
      maxLine: 1,
      shadowElevation: 2,
      notchGradient: AppColors.accentGradient,
      kBottomRadius: 28.h,
      notchColor: AppColors.accentDarkTeal,
      removeMargins: false,
      bottomBarWidth: MediaQuery.of(context).size.width,
      showShadow: true,
      durationInMilliSeconds: 300,
      itemLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      elevation: 1,
      kIconSize: 24.0,
      bottomBarItems: _buildBottomBarItems(),
      onTap: (index) {
        debugPrint('Current selected index $index');
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        setState(() {
          _currentIndex = index;
        });
        // Trigger fade animation
        _fadeController.reset();
        _fadeController.forward();
      },
    );
  }

  List<BottomBarItem> _buildBottomBarItems() {
    return AppRouteUtlis.routes.map((route) {
      return BottomBarItem(
        inActiveItem: FaIcon(
          route.icon,
          color: AppColors.textSecondary,
          size: 22,
        ),
        activeItem: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FaIcon(
            route.icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        itemLabel: route.name,
      );
    }).toList();
  }
}