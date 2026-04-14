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
// import 'package:mobile/features/track/data/websocket/price_tracking_websocket_service.dart';
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
  bool _hasCheckedForDialog = false;
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
        data: (state) {
          // Check for email dialog when state is loaded
          if (!_hasCheckedForDialog) {
            _hasCheckedForDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndShowEmailDialog();
            });
          }

          return _buildContent(state, isDark);
        },
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

  void _checkAndShowEmailDialog() {
    final notifier = ref.read(priceTrackingProvider.notifier);
    final hasEmail = notifier.hasCachedEmail();

    if (!hasEmail) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CreateAlertDialog(isFirstTime: true),
      );
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
      '🔍 BuildContent - Total: $totalTrackedProducts, Active: $activeAlerts, Triggered: $triggeredAlerts',
    );

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