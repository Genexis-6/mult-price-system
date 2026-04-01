import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/features/home/ui/screen/home_screen.dart';
import 'package:mobile/features/settings/ui/screen/settings_screen.dart';
import 'package:mobile/features/track/ui/screen/track_screen.dart';

class AppAvaliableRoute {
  final int index;
  final String path, name;
  final FaIconData icon;
  final Widget screen;
  final bool showBadge;
  final int? badgeCount;
  final Color? badgeColor;

  AppAvaliableRoute({
    required this.index,
    required this.path,
    required this.name,
    required this.icon,
    required this.screen,
    this.showBadge = false,
    this.badgeCount,
    this.badgeColor,
  });
}

class AppRouteUtlis {
  static List<AppAvaliableRoute> routes = [
    AppAvaliableRoute(
      screen: const HomeScreen(),
      index: 0,
      path: "/home",
      name: "Home",
      icon: FontAwesomeIcons.houseChimney,
    ),

    AppAvaliableRoute(
      screen: const TrackScreen(),
      index: 1,
      path: "/track",
      name: "Tracker",
      icon: FontAwesomeIcons.locationDot,
      showBadge: true, // Show badge if there are active tracks
      badgeCount: 3, // Number of active tracking items
      badgeColor: Colors.red,
    ),

    AppAvaliableRoute(
      screen: const SettingScreen(),
      index: 2,
      path: "/setting",
      name: "Settings",
      icon: FontAwesomeIcons.gear,
      showBadge: false, // No badge for settings
    ),
  ];
}
