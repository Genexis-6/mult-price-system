import 'package:go_router/go_router.dart';

import '../../features/home/routes.dart';
import 'ui/widgets/main_shell_widget.dart';


final shellRoutes = ShellRoute(
  builder: (context, state, child) {
    return MainShellWidgets();
  },
  
  routes: [
    GoRoute(
      path: '/app',
      redirect: (context, state) {
        var path = state.uri.path;

        return path.startsWith("/app") ? null : "/app/home";
      },
      routes: [homeRoutes],
    ),
  ],
);
