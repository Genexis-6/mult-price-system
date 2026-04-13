import 'package:go_router/go_router.dart';
import 'package:mobile/features/track/ui/screen/price_tracking_screen.dart';


final homeRoutes = GoRoute(
  path: "/track",
  builder: (context, state) => PriceTrackingScreen(),
);
