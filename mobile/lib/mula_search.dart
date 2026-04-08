import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';
import 'package:mobile/core/theme/app_theme.dart';

class MulaSearch extends ConsumerStatefulWidget {
  const MulaSearch({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MulaSearchState();
}

class _MulaSearchState extends ConsumerState<MulaSearch> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ref.read(appStateProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(appStateProvider);

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