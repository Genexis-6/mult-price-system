import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mobile/features/home/application/provider/home_provider.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  final WidgetRef ref;
  final Function(String status) onStatusChange;

  AppLifecycleHandler({
    required this.ref,
    required this.onStatusChange,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      onStatusChange("background");
    } else if (state == AppLifecycleState.resumed) {
      onStatusChange("active");

    }
  }
}