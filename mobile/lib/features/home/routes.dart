import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/ui/screen/home_screen.dart';

final homeRoutes = GoRoute(
  path: "/home",
  builder: (context, state) => HomeScreen(),
);
