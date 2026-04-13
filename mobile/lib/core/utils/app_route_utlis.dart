import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/data/model/recommendation_model.dart';
import 'package:mobile/features/home/ui/screen/home_screen.dart';
import 'package:mobile/features/home/ui/screen/recommendation_results_screen.dart';
import 'package:mobile/features/settings/ui/screen/settings_screen.dart';
import 'package:mobile/features/track/ui/screen/price_tracking_screen.dart';

import '../share/ui/widgets/main_shell_widget.dart';

class AppAvaliableRoute {
  final int index;
  final String path, name;
  final FaIconData icon;
  final Widget screen;
  final bool showBadge;
  final int? badgeCount;
  final Color? badgeColor;
  final List<RouteBase>? subRoutes;

  AppAvaliableRoute({
    required this.index,
    required this.path,
    required this.name,
    required this.icon,
    required this.screen,
    this.showBadge = false,
    this.badgeCount,
    this.badgeColor,
    this.subRoutes,
  });
}

class AppRouteUtlis {
  static List<AppAvaliableRoute> routes = [
    AppAvaliableRoute(
      screen: const HomeScreen(),
      index: 0,
      path: "/home",
      name: "Home",
      icon: FontAwesomeIcons.house,
      subRoutes: [
        GoRoute(
          path: "/recommendations",
          builder: (context, state) {
            var res = state.extra as RecommendationModel;
            return RecommendationResultsScreen(
              products: res.product,
              query: res.query,
            );
          },
        ),
      ],
    ),
    AppAvaliableRoute(
      screen: const PriceTrackingScreen(),
      index: 1,
      path: "/track",
      name: "Track",
      icon: FontAwesomeIcons.locationDot,
    ),
    AppAvaliableRoute(
      screen: const SettingScreen(),
      index: 2,
      path: "/settings",
      name: "Settings",
      icon: FontAwesomeIcons.gear,
    ),
  ];

  static void goScreen(BuildContext context, {required int index}) {
    for (var v in AppRouteUtlis.routes) {
      if (v.index == index) {
        context.go(v.path);
        return;
      }
    }
    return;
  }

  static GoRouter get router => GoRouter(
    initialLocation: "/home",
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShellWidgets(child: child),
        routes: [
          ...routes.map(
            (route) => GoRoute(
              path: route.path,
              name: route.name,
              routes: route.subRoutes != null ? route.subRoutes! : [],
              builder: (context, state) => route.screen,
            ),
          ),
        ],
      ),
    ],
  );
}
