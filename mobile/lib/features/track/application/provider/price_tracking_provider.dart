import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        return await _fetchUserAlertsFromApi(cachedEmail);
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

  void initializePriceTrackingWebSocket(String email) {
    if (_isDisposed) return;

    // Remove listener from old notifier before disposing
    if (_priceTrackingWebSocketNotifier != null) {
      try {
        // Don't dispose if it's the same email (avoid reconnection loop)
        if (_priceTrackingWebSocketNotifier!.email == email) {
          logger.d(
            'PriceTrackingWebSocket already initialized for email: $email',
          );
          return;
        }

        // Remove listener to prevent callbacks during disposal
        _priceTrackingWebSocketNotifier!.dispose();
      } catch (e) {
        logger.d('Error disposing old WebSocket notifier: $e');
      }
      _priceTrackingWebSocketNotifier = null;
    }

    // Small delay to ensure cleanup is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isDisposed) return;

      try {
        // Create new WebSocket notifier
        _priceTrackingWebSocketNotifier = ref.read(
          priceTrackingWebSocketProvider(email).notifier,
        );

        // Listen to state changes - FIX: Accept the state parameter
        _priceTrackingWebSocketNotifier!.addListener((
          PriceTrackingWebSocketState state,
        ) {
          if (!_isDisposed) {
            _onPriceTrackingWebSocketStateChanged();
          }
        });

        logger.d('PriceTrackingWebSocket initialized for email: $email');
      } catch (e) {
        logger.e('Failed to initialize WebSocket: $e');
      }
    });
  }

  void _onPriceTrackingWebSocketStateChanged() {
    if (_isDisposed || _priceTrackingWebSocketNotifier == null) return;

    final wsState = _priceTrackingWebSocketNotifier!.state;
    final lastMessage = wsState.lastMessage;

    if (lastMessage != null) {
      final type = lastMessage['type'] as String?;

      switch (type) {
        case 'alert_update':
          _updateSingleAlertFromPriceTrackingWebSocket(lastMessage);
          break;

        case 'initial_status':
        case 'refresh':
          _refreshFromPriceTrackingWebSocketData(wsState.initialAlerts);
          break;
      }
    }
  }

  void _updateSingleAlertFromPriceTrackingWebSocket(
    Map<String, dynamic> update,
  ) {
    if (_isDisposed) return;

    final currentState = state.value;
    if (currentState == null || !currentState.isLoaded) return;

    final loadedState = currentState.asLoaded!;
    final alertId = update['alert_id'] as int?;
    if (alertId == null) return;

    logger.d(
      'Updating alert $alertId from WebSocket: target_reached=${update['target_reached']}',
    );

    // Find the product in current state
    TrackedProduct? foundProduct;
    String? oldPlatform;
    bool wasInActive = false;
    bool wasInCancelled = false;

    // Check active platform tracking
    for (var platform in loadedState.platformTracking) {
      for (var product in platform.products) {
        if (product.id == alertId.toString()) {
          foundProduct = product;
          oldPlatform = platform.platform;
          wasInActive = true;
          break;
        }
      }
      if (foundProduct != null) break;
    }

    // Check cancelled if not found
    if (foundProduct == null) {
      for (var platform in loadedState.cancelledPlatformTracking) {
        for (var product in platform.products) {
          if (product.id == alertId.toString()) {
            foundProduct = product;
            oldPlatform = platform.platform;
            wasInCancelled = true;
            break;
          }
        }
        if (foundProduct != null) break;
      }
    }

    // If product not found at all, we can't update
    if (foundProduct == null) {
      logger.w('Alert $alertId not found in current state');
      return;
    }

    final newCurrentPrice = (update['current_best_price'] as num?)?.toDouble();
    final newPlatform = update['current_best_platform'] as String?;
    final targetReached = update['target_reached'] as bool? ?? false;

    // Create updated product
    final updatedProduct = foundProduct.copyWith(
      currentPrice: newCurrentPrice ?? foundProduct.currentPrice,
      platform: newPlatform ?? foundProduct.platform,
      isTargetReached: targetReached,
      status: targetReached
          ? 'triggered'
          : (foundProduct.status?.toLowerCase() == 'cancelled'
                ? 'cancelled'
                : 'active'),
      lastChecked: DateTime.now(),
      priceDifference: newCurrentPrice != null
          ? foundProduct.targetPrice - newCurrentPrice
          : foundProduct.priceDifference,
    );

    final targetPlatform = newPlatform ?? oldPlatform ?? 'unknown';

    // UPDATE PLATFORM TRACKING
    List<PlatformTracking> updatedPlatformTracking = [];

    for (var platform in loadedState.platformTracking) {
      var products = platform.products;

      if (platform.platform == oldPlatform && wasInActive) {
        // Remove the old product from this platform
        products = products.where((p) => p.id != alertId.toString()).toList();
      }

      // CRITICAL FIX: Only add to platform tracking if NOT triggered
      if (platform.platform == targetPlatform && !targetReached) {
        if (!products.any((p) => p.id == alertId.toString())) {
          products = [...products, updatedProduct];
        } else {
          products = products
              .map((p) => p.id == alertId.toString() ? updatedProduct : p)
              .toList();
        }
      }

      if (products.isNotEmpty) {
        updatedPlatformTracking.add(
          platform.copyWith(
            products: products,
            activeAlerts: products
                .where((p) => p.status?.toLowerCase() == 'active')
                .length,
            triggeredAlerts: products.where((p) => p.isTargetReached).length,
          ),
        );
      }
    }

    // If product is NOT triggered and platform doesn't exist, create it
    if (!targetReached &&
        !updatedPlatformTracking.any((p) => p.platform == targetPlatform)) {
      updatedPlatformTracking.add(
        PlatformTracking(
          platform: targetPlatform,
          products: [updatedProduct],
          activeAlerts: updatedProduct.status?.toLowerCase() == 'active'
              ? 1
              : 0,
          triggeredAlerts: 0,
          platformColor: _getPlatformColor(targetPlatform),
          platformIcon: _getPlatformIcon(targetPlatform),
        ),
      );
    }

    // UPDATE CANCELLED PLATFORM TRACKING
    List<PlatformTracking> updatedCancelledPlatformTracking = [];

    for (var platform in loadedState.cancelledPlatformTracking) {
      var products = platform.products;

      if (platform.platform == oldPlatform && wasInCancelled) {
        products = products.where((p) => p.id != alertId.toString()).toList();
      }

      if (platform.platform == targetPlatform &&
          updatedProduct.status?.toLowerCase() == 'cancelled') {
        if (!products.any((p) => p.id == alertId.toString())) {
          products = [...products, updatedProduct];
        }
      }

      if (products.isNotEmpty) {
        updatedCancelledPlatformTracking.add(
          platform.copyWith(products: products),
        );
      }
    }

    // UPDATE BEST DEALS - Only for triggered alerts
    List<BestDeal> updatedBestDeals = List.from(loadedState.bestDeals);
    final existingDealIndex = updatedBestDeals.indexWhere(
      (d) => d.id == alertId.toString(),
    );

    if (targetReached &&
        newCurrentPrice != null &&
        newCurrentPrice <= updatedProduct.targetPrice) {
      final savings = updatedProduct.targetPrice - newCurrentPrice;
      final savingsPercentage = updatedProduct.targetPrice > 0
          ? (savings / updatedProduct.targetPrice) * 100
          : 0;

      final newDeal = BestDeal(
        id: alertId.toString(),
        productName: updatedProduct.productName,
        price: newCurrentPrice,
        targetPrice: updatedProduct.targetPrice,
        platform: newPlatform ?? updatedProduct.platform,
        savings: savings,
        savingsPercentage: savingsPercentage.toDouble(),
        triggeredAt: DateTime.now(),
        productUrl: null,
      );

      if (existingDealIndex >= 0) {
        updatedBestDeals[existingDealIndex] = newDeal;
      } else {
        updatedBestDeals.add(newDeal);
      }

      updatedBestDeals.sort(
        (a, b) => b.savingsPercentage.compareTo(a.savingsPercentage),
      );
      logger.d(
        '✅ Added/Updated best deal for alert $alertId (removed from active section)',
      );
    } else if (!targetReached && existingDealIndex >= 0) {
      updatedBestDeals.removeAt(existingDealIndex);
      logger.d('❌ Removed best deal for alert $alertId');
    }

    // RECALCULATE OVERALL STATS
    final allActiveTriggered = updatedPlatformTracking
        .expand((p) => p.products)
        .toList();
    final totalTracked = allActiveTriggered.length;
    final activeAlerts = allActiveTriggered
        .where((p) => p.status?.toLowerCase() == 'active')
        .length;
    final triggeredAlerts = allActiveTriggered
        .where((p) => p.isTargetReached)
        .length;

    double potentialSavings = 0;
    for (var product in allActiveTriggered) {
      if (product.isTargetReached &&
          product.currentPrice != null &&
          product.currentPrice! < product.targetPrice) {
        potentialSavings += product.targetPrice - product.currentPrice!;
      }
    }

    final newState = loadedState.copyWith(
      platformTracking: updatedPlatformTracking,
      cancelledPlatformTracking: updatedCancelledPlatformTracking,
      bestDeals: updatedBestDeals,
      totalTrackedProducts: totalTracked,
      activeAlerts: activeAlerts,
      triggeredAlerts: triggeredAlerts,
      potentialSavings: potentialSavings,
    );

    state = AsyncValue.data(newState);

    logger.d(
      '📊 State updated - Total: $totalTracked, Active: $activeAlerts, Triggered: $triggeredAlerts, Best Deals: ${updatedBestDeals.length}',
    );
  }

  void _refreshFromPriceTrackingWebSocketData(
    List<Map<String, dynamic>> alerts,
  ) {
    if (_isDisposed || alerts.isEmpty) return;

    logger.d('Refreshing from WebSocket data: ${alerts.length} alerts');

    final activeAndTriggered = alerts
        .where((a) => (a['status'] as String?)?.toLowerCase() != 'cancelled')
        .toList();

    final cancelled = alerts
        .where((a) => (a['status'] as String?)?.toLowerCase() == 'cancelled')
        .toList();

    final platformTracking = _convertWebSocketAlertsToPlatformTracking(
      activeAndTriggered,
    );
    final cancelledPlatformTracking = _convertWebSocketAlertsToPlatformTracking(
      cancelled,
    );
    final bestDeals = _generateBestDealsFromWebSocketAlerts(activeAndTriggered);

    final totalTracked = activeAndTriggered.length;
    final active = activeAndTriggered
        .where((a) => (a['status'] as String?)?.toLowerCase() == 'active')
        .length;
    final triggered = activeAndTriggered
        .where((a) => (a['status'] as String?)?.toLowerCase() == 'triggered')
        .length;

    double savings = 0;
    for (var alert in activeAndTriggered) {
      if ((alert['status'] as String?)?.toLowerCase() == 'triggered') {
        final target = (alert['target_price'] as num?)?.toDouble() ?? 0;
        final current = (alert['current_best_price'] as num?)?.toDouble();
        if (current != null && current < target) {
          savings += target - current;
        }
      }
    }

    final currentState = state.value;
    final email = currentState?.isLoaded == true
        ? currentState!.cachedEmail
        : null;

    state = AsyncValue.data(
      PriceTrackingState.loaded(
        cachedEmail: email,
        platformTracking: platformTracking,
        cancelledPlatformTracking: cancelledPlatformTracking,
        bestDeals: bestDeals,
        totalTrackedProducts: totalTracked,
        activeAlerts: active,
        triggeredAlerts: triggered,
        cancelledAlerts: cancelled.length,
        potentialSavings: savings,
      ),
    );
  }

  List<PlatformTracking> _convertWebSocketAlertsToPlatformTracking(
    List<Map<String, dynamic>> alerts,
  ) {
    final Map<String, List<TrackedProduct>> platformMap = {};

    for (var alert in alerts) {
      final platform = alert['current_best_platform'] as String? ?? 'pending';
      final currentPrice = (alert['current_best_price'] as num?)?.toDouble();
      final targetPrice = (alert['target_price'] as num?)?.toDouble() ?? 0;
      final status = alert['status'] as String? ?? 'active';

      final trackedProduct = TrackedProduct(
        id: (alert['id'] as int).toString(),
        productName: alert['product_name'] as String? ?? '',
        targetPrice: targetPrice,
        currentPrice: currentPrice,
        platform: platform,
        priceDifference: currentPrice != null ? targetPrice - currentPrice : 0,
        isTargetReached: status.toLowerCase() == 'triggered',
        lastChecked: DateTime.now(),
        productUrl: null,
        status: status,
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

  List<BestDeal> _generateBestDealsFromWebSocketAlerts(
    List<Map<String, dynamic>> alerts,
  ) {
    return alerts
        .where((a) => (a['status'] as String?)?.toLowerCase() == 'triggered')
        .map((alert) {
          final targetPrice = (alert['target_price'] as num?)?.toDouble() ?? 0;
          final currentPrice =
              (alert['current_best_price'] as num?)?.toDouble() ?? targetPrice;
          final savings = targetPrice - currentPrice;
          final savingsPercentage = targetPrice > 0
              ? (savings / targetPrice) * 100
              : 0;

          return BestDeal(
            id: (alert['id'] as int).toString(),
            productName: alert['product_name'] as String? ?? '',
            price: currentPrice,
            targetPrice: targetPrice,
            platform: alert['current_best_platform'] as String? ?? 'unknown',
            savings: savings,
            savingsPercentage: savingsPercentage.toDouble(),
            triggeredAt: DateTime.now(),
            productUrl: null,
          );
        })
        .toList()
      ..sort((a, b) => b.savingsPercentage.compareTo(a.savingsPercentage));
  }

  // MARK: - API Methods
  Future<PriceTrackingState> _fetchUserAlertsFromApi(String email) async {
    try {
      final api = ref.read(priceTrackingApi);
      final response = await api.getUserAlerts(email);

      if (response.success && response.data != null) {
        final allAlerts = response.data!.data;

        final activeAndTriggeredAlerts = allAlerts
            .where((a) => a.status.toLowerCase() != 'cancelled')
            .toList();

        final cancelledAlertsList = allAlerts
            .where((a) => a.status.toLowerCase() == 'cancelled')
            .toList();

        logger.d(
          'Total: ${allAlerts.length}, Active/Triggered: ${activeAndTriggeredAlerts.length}, Cancelled: ${cancelledAlertsList.length}',
        );

        final platformTracking = _convertAlertsToPlatformTracking(
          activeAndTriggeredAlerts,
        );
        final cancelledPlatformTracking = _convertAlertsToPlatformTracking(
          cancelledAlertsList,
        );
        final bestDeals = _generateBestDealsFromAlerts(
          activeAndTriggeredAlerts,
        );

        final totalTrackedProducts = activeAndTriggeredAlerts.length;
        final cancelledAlerts = cancelledAlertsList.length;

        final activeAlerts = activeAndTriggeredAlerts
            .where((a) => a.status.toLowerCase() == 'active')
            .length;

        final triggeredAlerts = activeAndTriggeredAlerts
            .where((a) => a.status.toLowerCase() == 'triggered')
            .length;

        double potentialSavings = 0;
        for (var alert in activeAndTriggeredAlerts) {
          if (alert.status.toLowerCase() == 'triggered' &&
              alert.currentBestPrice != null &&
              alert.currentBestPrice! < alert.targetPrice) {
            potentialSavings += alert.targetPrice - alert.currentBestPrice!;
          }
        }

        // Schedule WebSocket initialization after state is set
        Future.microtask(() {
          if (!_isDisposed) {
            initializePriceTrackingWebSocket(email);
          }
        });

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
        productUrl: null,
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
    return alerts
        .where(
          (a) =>
              a.status.toLowerCase() == 'triggered' &&
              a.currentBestPrice != null,
        )
        .map((alert) {
          final savings = alert.targetPrice - alert.currentBestPrice!;
          final savingsPercentage = (savings / alert.targetPrice) * 100;

          return BestDeal(
            id: alert.id.toString(),
            productName: alert.productName,
            price: alert.currentBestPrice!,
            targetPrice: alert.targetPrice,
            platform: alert.currentBestPlatform ?? 'unknown',
            savings: savings,
            savingsPercentage: savingsPercentage,
            triggeredAt: alert.updatedAt ?? alert.createdAt,
            productUrl: null,
          );
        })
        .toList()
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

  // Update an alert's target price
  // Update an alert's target price
  // Update an alert's target price
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

      if (response.success && response.data != null) {
        logger.d(
          'Alert updated: ${response.data!.data.productName} -> ₦${response.data!.data.targetPrice}',
        );
        // Refresh data to show updated price
        await refreshData();
        return true;
      }

      logger.w('Update alert failed: ${response.message}');
      return false;
    } catch (e) {
      logger.e('Failed to update alert: $e');
      return false;
    }
  }

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

  void sendWebSocketRefresh() {
    _priceTrackingWebSocketNotifier?.sendRefresh();
  }

  void reconnectWebSocket() {
    _priceTrackingWebSocketNotifier?.reconnect();
  }

  // @override
  void dispose() {
    _isDisposed = true;
    if (_priceTrackingWebSocketNotifier != null) {
      try {
        _priceTrackingWebSocketNotifier!.dispose();
      } catch (e) {
        logger.d('Error disposing WebSocket notifier: $e');
      }
      _priceTrackingWebSocketNotifier = null;
    }
    // super.dispose();
  }
}
