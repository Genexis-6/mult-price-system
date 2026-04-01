import 'package:go_router/go_router.dart';
import 'package:mobile/features/settings/ui/screen/settings_screen.dart';

final homeRoutes = GoRoute(
  path: "/setting",
  builder: (context, state) => SettingScreen(),
);
