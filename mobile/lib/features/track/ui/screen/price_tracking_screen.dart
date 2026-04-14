import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile/core/share/ui/widgets/custom_snack_bar.dart';
import 'package:mobile/core/share/ui/widgets/custom_text.dart';
import 'package:mobile/core/share/ui/widgets/splash_widget.dart';
import 'package:mobile/core/theme/app_color.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:mobile/features/track/application/provider/price_tracking_provider.dart';
import 'package:mobile/features/track/application/provider/price_tracking_wesocket_provider.dart';
import 'package:mobile/features/track/application/state/price_tracking_state.dart';
import 'package:mobile/features/track/data/webcoket/price_tracking_websocket_service.dart';
import 'package:mobile/features/track/ui/widgets/best_deal_section.dart';
import 'package:mobile/features/track/ui/widgets/cancled_section.dart';
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
  bool _webSocketInitialized = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackingStateAsync = ref.watch(priceTrackingProvider);

    // Initialize WebSocket when state is loaded and email is available
    _initializeWebSocketIfNeeded();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: trackingStateAsync.when(
        data: (state) => _buildContent(state, isDark),
        loading: () => const SplashScreen(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText('Error: $error', color: Colors.red),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(priceTrackingProvider.notifier).refreshData(),
                child: const CustomText('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeWebSocketIfNeeded() {
    if (_webSocketInitialized) return;
    
    final trackingState = ref.read(priceTrackingProvider).value;
    if (trackingState != null && trackingState.isLoaded) {
      final loadedState = trackingState.asLoaded!;
      final email = loadedState.cachedEmail;
      
      if (email != null && email.isNotEmpty) {
        _webSocketInitialized = true;
        logger.d('PriceTrackingScreen: WebSocket ready for email: $email');
      }
    }
  }

  Widget _buildConnectionStatus(String email) {
    final wsState = ref.watch(priceTrackingWebSocketProvider(email));
    
    Color statusColor;
    String tooltip;
    
    switch (wsState.connectionState) {
      case PriceTrackingWebSocketConnectionState.connected:
        statusColor = Colors.green;
        tooltip = 'Real-time updates connected';
        break;
      case PriceTrackingWebSocketConnectionState.connecting:
        statusColor = Colors.orange;
        tooltip = 'Connecting to real-time updates...';
        break;
      case PriceTrackingWebSocketConnectionState.error:
        statusColor = Colors.red;
        tooltip = 'Connection error - tap to reconnect';
        break;
      default:
        statusColor = Colors.grey;
        tooltip = 'Real-time updates disconnected';
    }
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (wsState.connectionState != PriceTrackingWebSocketConnectionState.connected &&
              wsState.connectionState != PriceTrackingWebSocketConnectionState.connecting) {
            ref.read(priceTrackingProvider.notifier).reconnectWebSocket();
            CustomSnackbar.info(
              context: context,
              message: 'Reconnecting to real-time updates...',
            );
          }
        },
        child: Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.5),
                blurRadius: 6.r,
                spreadRadius: 1.r,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PriceTrackingState state, bool isDark) {
    if (!state.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final loadedState = state.asLoaded!;
    final userEmail = loadedState.cachedEmail ?? 'guest@example.com';
    final hasEmail = loadedState.cachedEmail != null && loadedState.cachedEmail!.isNotEmpty;
    final platformTracking = loadedState.platformTracking;
    final cancelledPlatformTracking = loadedState.cancelledPlatformTracking;
    final bestDeals = loadedState.bestDeals;
    final totalTrackedProducts = loadedState.totalTrackedProducts;
    final activeAlerts = loadedState.activeAlerts;
    final triggeredAlerts = loadedState.triggeredAlerts;
    final potentialSavings = loadedState.potentialSavings;
    final isRefreshing = loadedState.isRefreshing;

    // Debug print
    debugPrint(
      '🔍 BuildContent - Total: $totalTrackedProducts, Active: $activeAlerts, Triggered: $triggeredAlerts, HasEmail: $hasEmail',
    );

    // If no email is cached, show the welcome screen
    if (!hasEmail) {
      return _buildWelcomeScreen(isDark);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(priceTrackingProvider.notifier).refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with connection status
              Stack(
                children: [
                  TrackingHeader(
                    userEmail: userEmail,
                    totalTrackedProducts: totalTrackedProducts,
                    activeAlerts: activeAlerts,
                    triggeredAlerts: triggeredAlerts,
                    potentialSavings: potentialSavings,
                    onAddAlert: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            const CreateAlertDialog(isFirstTime: false),
                      );
                    },
                  ),
                  // Connection status indicator
                  if (loadedState.cachedEmail != null && loadedState.cachedEmail!.isNotEmpty)
                    Positioned(
                      top: 16.h,
                      right: 70.w,
                      child: _buildConnectionStatus(loadedState.cachedEmail!),
                    ),
                ],
              ),
              SizedBox(height: 8.h),

              // Show loading indicator when refreshing
              if (isRefreshing)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primary : AppColors.primary,
                  ),
                  minHeight: 2.h,
                ),

              // Best Deals Section
              BestDealsSection(deals: bestDeals, isDark: isDark),
              SizedBox(height: 16.h),

              // Active/Triggered Platform Sections
              if (platformTracking.isEmpty)
                _buildEmptyState(isDark)
              else
                ...platformTracking.map((platform) {
                  return PlatformSection(platform: platform, isDark: isDark);
                }),

              // Cancelled Section (shown at the bottom)
              if (cancelledPlatformTracking.isNotEmpty) ...[
                SizedBox(height: 16.h),
                CancelledSection(
                  cancelledPlatforms: cancelledPlatformTracking,
                  isDark: isDark,
                ),
              ],

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isDark) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20.r,
                      spreadRadius: 5.r,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 64.sp,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Title
              CustomText(
                'Track Prices Like a Pro',
                type: TextType.headlineMedium,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              
              // Subtitle
              CustomText(
                'Never miss a price drop again. Set your target price and we\'ll notify you when it\'s time to buy.',
                type: TextType.bodyMedium,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              SizedBox(height: 32.h),
              
              // Features
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureChip(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Jumia',
                    color: const Color(0xFFFF6B00),
                  ),
                  SizedBox(width: 12.w),
                  _buildFeatureChip(
                    icon: Icons.store_rounded,
                    label: 'Konga',
                    color: const Color(0xFFFF0066),
                  ),
                  SizedBox(width: 12.w),
                  _buildFeatureChip(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Jiji',
                    color: const Color(0xFF00D084),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              
              // Benefits
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      icon: Icons.notifications_active_rounded,
                      text: 'Real-time price alerts',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    _buildBenefitRow(
                      icon: Icons.trending_down_rounded,
                      text: 'Track price history',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    _buildBenefitRow(
                      icon: Icons.compare_arrows_rounded,
                      text: 'Compare across platforms',
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    _buildBenefitRow(
                      icon: Icons.savings_rounded,
                      text: 'Save money on every purchase',
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              
              // CTA Button
              Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const CreateAlertDialog(isFirstTime: true),
                      );
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          CustomText(
                            'Start Tracking Now',
                            type: TextType.titleMedium,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              
              // Terms
              CustomText(
                'By continuing, you agree to receive price alert notifications',
                type: TextType.bodySmall,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
                fontSize: 11.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 6.w),
          CustomText(
            label,
            type: TextType.bodySmall,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomText(
            text,
            type: TextType.bodyMedium,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 18.sp,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64.sp,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          CustomText(
            'No alerts yet',
            type: TextType.titleMedium,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          SizedBox(height: 8.h),
          CustomText(
            'Tap + to create your first price alert',
            type: TextType.bodyMedium,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>
                    const CreateAlertDialog(isFirstTime: true),
              );
            },
            icon: Icon(Icons.add_alert_rounded, size: 18.sp),
            label: CustomText('Create Alert', type: TextType.bodyMedium),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}