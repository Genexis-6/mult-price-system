import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/features/track/data/model/dummy_data_model.dart';
import 'package:mobile/features/track/ui/widgets/best_deal_section.dart';
import 'package:mobile/features/track/ui/widgets/platform_sections.dart';
import 'package:mobile/features/track/ui/widgets/tracking_header.dart';
import 'package:mobile/features/track/ui/widgets/create_alert_dialog.dart';

class PriceTrackingScreen extends ConsumerStatefulWidget {
  const PriceTrackingScreen({super.key});

  @override
  ConsumerState<PriceTrackingScreen> createState() =>
      _PriceTrackingScreenState();
}

class _PriceTrackingScreenState extends ConsumerState<PriceTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const userEmail = 'john.doe@example.com';
    final platformTracking = DummyPriceData.getPlatformTracking();
    final bestDeals = DummyPriceData.getBestDeals();
    final totalTrackedProducts = platformTracking.fold(
      0,
      (sum, platform) => sum + platform.products.length,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrackingHeader(
                userEmail: userEmail,
                totalTrackedProducts: totalTrackedProducts,
                onAddAlert: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateAlertDialog(),
                  );
                },
              ),
              SizedBox(height: 8.h),
              BestDealsSection(deals: bestDeals, isDark: isDark),
              SizedBox(height: 16.h),
              ...platformTracking.map((platform) {
                return PlatformSection(platform: platform, isDark: isDark);
              }),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
