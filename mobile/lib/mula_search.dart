import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';
import 'core/theme/app_theme.dart';

class MulaSearch extends ConsumerWidget {
  const MulaSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   
    
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: AppRouteUtlis.router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}