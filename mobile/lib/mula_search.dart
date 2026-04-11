import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/lifecycle/app_lifecycle_handler.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/core/utils/app_route_utlis.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/application/provider/home_provider.dart';

class MulaSearch extends ConsumerStatefulWidget {
  const MulaSearch({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MulaSearchState();
}

class _MulaSearchState extends ConsumerState<MulaSearch> with WidgetsBindingObserver {
  late AppLifecycleHandler _lifecycleHandler;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await ref.read(appStateProvider.future);
    var res = ref.read(appBackgroundUpdateProvider);
    
    _lifecycleHandler = AppLifecycleHandler(
      ref: ref,
      onStatusChange: (status) {
        switch (status) {
          case "background":
            res.checkTaskRunning();
            break;
          case "active":
            var _ = ref.refresh(homeProvider);
            break;
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleHandler.didChangeAppLifecycleState(state);
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