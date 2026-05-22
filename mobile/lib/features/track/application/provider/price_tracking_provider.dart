// price_tracking_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:mobile/features/track/application/provider/price_tracking_wesocket_provider.dart';
import 'package:mobile/features/track/application/state/price_tracking_state.dart';
import 'package:mobile/features/track/data/api/price_tracking_api.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
import 'package:mobile/features/track/data/model/price_tracking_res_model.dart';
import 'package:mobile/features/track/application/provider/repo_provider.dart';

final priceTrackingProvider =
    AsyncNotifierProvider<PriceTrackingProvider, PriceTrackingState>(
      PriceTrackingProvider.new,
    );

class PriceTrackingProvider extends AsyncNotifier<PriceTrackingState> {
  static const String _cachedEmailKey = 'cached_user_email';

  PriceTrackingWebSocketNotifier? _priceTrackingWebSocketNotifier;
  bool _isDisposed = false;

  @override
  FutureOr<PriceTrackingState> build() async {
    _isDisposed = false;
    state = const AsyncValue.data(PriceTrackingState.loading());

    try {
      final cachedEmail = await _loadCachedEmail();

      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        final result = await _fetchUserAlertsFromApi(cachedEmail);
        // Initialize WebSocket after fetching data
        Future.microtask(() {
          if (!_isDisposed) {
            initializePriceTrackingWebSocket(cachedEmail);
          }
        });
        return result;
      }

      return PriceTrackingState.loaded(
        cachedEmail: null,
        platformTracking: [],
        cancelledPlatformTracking: [],
        bestDeals: [],
        totalTrackedProducts: 0,
        activeAlerts: 0,
        triggeredAlerts: 0,
        cancelledAlerts: 0,
        potentialSavings: 0,
      );
    } catch (e) {
      return PriceTrackingState.error(
        message: 'Failed to load tracking data: $e',
        cachedEmail: await _loadCachedEmail(),
      );
    }
  }

  // MARK: - WebSocket Lifecycle Management

  void initializePriceTrackingWebSocket(String email) {
    if (_isDisposed) return;

    // If already initialized with the same email, don't reinitialize
    if (_priceTrackingWebSocketNotifier != null && 
        _priceTrackingWebSocketNotifier!.email == email) {
      logger.d('PriceTrackingWebSocket already initialized for email: $email');
      return;
    }

    // Dispose existing WebSocket if any
    disposeWebSocket();

    // Create new WebSocket notifier
    _priceTrackingWebSocketNotifier = ref.read(
      priceTrackingWebSocketProvider(email).notifier,
    );

    logger.d('✅ PriceTrackingWebSocket initialized for email: $email');
  }

  void disposeWebSocket() {
    if (_priceTrackingWebSocketNotifier != null) {
      try {
        _priceTrackingWebSocketNotifier!.dispose();
        _priceTrackingWebSocketNotifier = null;
        logger.d('🗑️ PriceTrackingProvider: WebSocket disposed');
      } catch (e) {
        logger.e('Error disposing WebSocket: $e');
      }
    }
  }

  void reconnectWebSocketIfNeeded() {
    if (_isDisposed) return;

    final currentState = state.value;
    if (currentState != null && currentState.isLoaded) {
      final email = currentState.cachedEmail;
      if (email != null && email.isNotEmpty) {
        if (_priceTrackingWebSocketNotifier == null) {
          initializePriceTrackingWebSocket(email);
          logger.d('🔄 PriceTrackingProvider: WebSocket reconnected');
        }
      }
    }
  }

  // MARK: - API Methods

  Future<PriceTrackingState> _fetchUserAlertsFromApi(String email) async {
    try {
      final api = ref.read(priceTrackingApi);
      final response = await api.getUserAlerts(email);

      if (response.success && response.data != null) {
        final allAlerts = response.data!.data;

        final activeAlertsList = allAlerts
            .where((a) => a.status.toLowerCase() == 'active')
            .toList();

        final triggeredAlertsList = allAlerts
            .where((a) => a.status.toLowerCase() == 'triggered')
            .toList();

        final cancelledAlertsList = allAlerts
            .where((a) => a.status.toLowerCase() == 'cancelled')
            .toList();

        logger.d(
          'Total: ${allAlerts.length}, Active: ${activeAlertsList.length}, Triggered: ${triggeredAlertsList.length}, Cancelled: ${cancelledAlertsList.length}',
        );

        final platformTracking = _convertAlertsToPlatformTracking(
          activeAlertsList,
        );
        final cancelledPlatformTracking = _convertAlertsToPlatformTracking(
          cancelledAlertsList,
        );
        final bestDeals = _generateBestDealsFromAlerts(triggeredAlertsList);

        final totalTrackedProducts = activeAlertsList.length;
        final activeAlerts = activeAlertsList.length;
        final triggeredAlerts = bestDeals.length;
        final cancelledAlerts = cancelledAlertsList.length;

        double potentialSavings = 0;
        for (var deal in bestDeals) {
          if (deal.price < deal.targetPrice) {
            potentialSavings += deal.targetPrice - deal.price;
          }
        }

        return PriceTrackingState.loaded(
          cachedEmail: email,
          platformTracking: platformTracking,
          cancelledPlatformTracking: cancelledPlatformTracking,
          bestDeals: bestDeals,
          totalTrackedProducts: totalTrackedProducts,
          activeAlerts: activeAlerts,
          triggeredAlerts: triggeredAlerts,
          cancelledAlerts: cancelledAlerts,
          potentialSavings: potentialSavings,
        );
      }

      return PriceTrackingState.loaded(
        cachedEmail: email,
        platformTracking: [],
        cancelledPlatformTracking: [],
        bestDeals: [],
        totalTrackedProducts: 0,
        activeAlerts: 0,
        triggeredAlerts: 0,
        cancelledAlerts: 0,
        potentialSavings: 0,
      );
    } catch (e) {
      logger.e('Failed to fetch alerts: $e');
      return PriceTrackingState.error(
        message: 'Failed to fetch alerts: $e',
        cachedEmail: email,
      );
    }
  }

  List<PlatformTracking> _convertAlertsToPlatformTracking(
    List<PriceAlertResponse> alerts,
  ) {
    final Map<String, List<TrackedProduct>> platformMap = {};

    for (var alert in alerts) {
      final platform = alert.currentBestPlatform ?? 'pending';
      final priceDifference = alert.currentBestPrice != null
          ? alert.targetPrice - alert.currentBestPrice!
          : 0.0;

      final trackedProduct = TrackedProduct(
        id: alert.id.toString(),
        productName: alert.productName,
        targetPrice: alert.targetPrice,
        currentPrice: alert.currentBestPrice,
        platform: platform,
        priceDifference: priceDifference,
        isTargetReached: alert.status.toLowerCase() == 'triggered',
        lastChecked: alert.updatedAt ?? alert.createdAt,
        productUrl: alert.currentBestUrl,
        status: alert.status,
        priceHistory: [],
      );

      platformMap.putIfAbsent(platform, () => []).add(trackedProduct);
    }

    return platformMap.entries.map((entry) {
      final platform = entry.key;
      final products = entry.value;
      final activeAlerts = products
          .where((p) => p.status?.toLowerCase() == 'active')
          .length;
      final triggeredAlerts = products.where((p) => p.isTargetReached).length;

      return PlatformTracking(
        platform: platform,
        products: products,
        activeAlerts: activeAlerts,
        triggeredAlerts: triggeredAlerts,
        platformColor: _getPlatformColor(platform),
        platformIcon: _getPlatformIcon(platform),
      );
    }).toList();
  }

  List<BestDeal> _generateBestDealsFromAlerts(List<PriceAlertResponse> alerts) {
    return alerts.where((a) => a.currentBestPrice != null).map((alert) {
        final savings = alert.targetPrice - alert.currentBestPrice!;
        final savingsPercentage = alert.targetPrice > 0
            ? (savings / alert.targetPrice) * 100
            : 0;

        final rawUrl = alert.currentBestUrl;
        final cleanUrl = rawUrl
            ?.replaceAll('\n', '')
            .replaceAll('\r', '')
            .replaceAll(' ', '')
            .trim();

        logger.d(
          'Creating BestDeal for ${alert.productName} with URL: $cleanUrl',
        );

        return BestDeal(
          id: alert.id.toString(),
          productName: alert.productName,
          price: alert.currentBestPrice!,
          targetPrice: alert.targetPrice,
          platform: alert.currentBestPlatform ?? 'unknown',
          savings: savings,
          savingsPercentage: savingsPercentage.toDouble(),
          triggeredAt: alert.updatedAt ?? alert.createdAt,
          productUrl: cleanUrl,
        );
      }).toList()
      ..sort((a, b) => b.savingsPercentage.compareTo(a.savingsPercentage));
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return const Color(0xFFFF6B00);
      case 'konga':
        return const Color(0xFFFF0066);
      case 'jiji':
        return const Color(0xFF00D084);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'jumia':
        return Icons.shopping_bag_rounded;
      case 'konga':
        return Icons.store_rounded;
      case 'jiji':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }

  // MARK: - Storage Methods

  Future<String?> _loadCachedEmail() async {
    try {
      final storageRepo = ref.read(appStorageProvider);
      return storageRepo.get<String>(key: _cachedEmailKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheUserEmail(String email) async {
    try {
      final storageRepo = ref.read(appStorageProvider);
      storageRepo.save<String>(key: _cachedEmailKey, val: email);

      final currentState = state.value;
      if (currentState != null && currentState.isLoaded) {
        final loadedState = currentState.asLoaded!;
        state = AsyncValue.data(loadedState.updateCachedEmail(email));
      }
    } catch (e) {
      throw Exception('Failed to cache email: $e');
    }
  }

  String? getCachedEmail() {
    final currentState = state.value;
    return currentState?.cachedEmail;
  }

  bool hasCachedEmail() {
    final email = getCachedEmail();
    return email != null && email.isNotEmpty;
  }

  Future<void> clearCachedEmail() async {
    try {
      final storageRepo = ref.read(appStorageProvider);
      await storageRepo.delete(key: _cachedEmailKey);

      final currentState = state.value;
      if (currentState != null && currentState.isLoaded) {
        final loadedState = currentState.asLoaded!;
        state = AsyncValue.data(loadedState.updateCachedEmail(null));
      }
    } catch (e) {
      throw Exception('Failed to clear cached email: $e');
    }
  }

  // MARK: - Public Methods

  Future<void> refreshData() async {
    if (_isDisposed) return;

    final currentState = state.value;
    if (currentState != null && currentState.isLoaded) {
      final loadedState = currentState.asLoaded!;

      state = AsyncValue.data(loadedState.setRefreshing(true));

      try {
        final email = loadedState.cachedEmail;
        if (email != null && email.isNotEmpty) {
          final newState = await _fetchUserAlertsFromApi(email);
          state = AsyncValue.data(newState);
        } else {
          state = AsyncValue.data(loadedState.setRefreshing(false));
        }
      } catch (e) {
        state = AsyncValue.data(
          PriceTrackingState.error(
            message: 'Failed to refresh: $e',
            cachedEmail: loadedState.cachedEmail,
          ),
        );
      }
    }
  }

  Future<void> createAlert({
    required String productName,
    required double targetPrice,
    required String email,
  }) async {
    if (_isDisposed) return;

    state = const AsyncValue.data(PriceTrackingState.creatingAlert());

    try {
      final api = ref.read(priceTrackingApi);
      final response = await api.createPriceAlert(
        email: email,
        productName: productName,
        targetPrice: targetPrice,
      );

      if (response.success) {
        if (response.data != null) {
          final alertData = response.data!.data;
          ref
              .read(appStateProvider.notifier)
              .storeDeviceTask(alertData.alertId.toString());
        }

        await cacheUserEmail(email);
        final newState = await _fetchUserAlertsFromApi(email);
        state = AsyncValue.data(newState);
      } else {
        final currentEmail = getCachedEmail();
        if (currentEmail != null && currentEmail.isNotEmpty) {
          final loadedState = await _fetchUserAlertsFromApi(currentEmail);
          state = AsyncValue.data(loadedState);
        } else {
          state = AsyncValue.data(
            PriceTrackingState.loaded(
              cachedEmail: null,
              platformTracking: [],
              cancelledPlatformTracking: [],
              bestDeals: [],
              totalTrackedProducts: 0,
              activeAlerts: 0,
              triggeredAlerts: 0,
              cancelledAlerts: 0,
              potentialSavings: 0,
            ),
          );
        }
        throw Exception(response.message);
      }
    } catch (e) {
      logger.e('Failed to create alert: $e');

      final currentEmail = getCachedEmail();
      if (currentEmail != null && currentEmail.isNotEmpty) {
        final loadedState = await _fetchUserAlertsFromApi(currentEmail);
        state = AsyncValue.data(loadedState);
      } else {
        state = AsyncValue.data(
          PriceTrackingState.error(
            message: 'Failed to create alert: $e',
            cachedEmail: getCachedEmail(),
          ),
        );
      }
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<bool> cancelAlert(int alertId) async {
    try {
      final api = ref.read(priceTrackingApi);
      final response = await api.cancelAlert(alertId);

      if (response.success) {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Failed to cancel alert: $e');
      return false;
    }
  }

  Future<bool> updateAlert({
    required int alertId,
    required double targetPrice,
  }) async {
    try {
      final api = ref.read(priceTrackingApi);
      final response = await api.updateAlert(
        alertId: alertId,
        targetPrice: targetPrice,
      );

      if (response.success) {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Failed to update alert: $e');
      return false;
    }
  }

  void sendWebSocketRefresh() {
    _priceTrackingWebSocketNotifier?.sendRefresh();
  }

  void reconnectWebSocket() {
    _priceTrackingWebSocketNotifier?.reconnect();
  }

  void dispose() {
    _isDisposed = true;
    disposeWebSocket();
  }
}