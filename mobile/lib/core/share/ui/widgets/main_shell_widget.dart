import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';

class MainShellWidgets extends ConsumerStatefulWidget {
  const MainShellWidgets({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MainShellWidgetsState();
}

class _MainShellWidgetsState extends ConsumerState<MainShellWidgets> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: widget.child,
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
              icon: FaIcon(
                tab.icon,
                size: 22.sp,
              ),
              activeIcon: FaIcon(
                tab.icon,
                size: 24.sp,
              ),
              label: tab.name,
            );
          }).toList(),
        ),
      ),
    );
  }
}