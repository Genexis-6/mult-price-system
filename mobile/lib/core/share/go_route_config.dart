import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/share/main_shell_route.dart';
import 'package:mobile/core/share/ui/ui.dart';

final mainRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      shellRoutes
    ],
    initialLocation: "/app/home",
    errorBuilder: (context, state) => PageNotFound(),
    
  ),
);
