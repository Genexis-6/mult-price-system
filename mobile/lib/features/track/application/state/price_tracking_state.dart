import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';

part 'price_tracking_state.freezed.dart';

@freezed
sealed class PriceTrackingState with _$PriceTrackingState {
  const factory PriceTrackingState.initial() = _Initial;
  
  const factory PriceTrackingState.loading() = _Loading;
  
  const factory PriceTrackingState.loaded({
    required String? cachedEmail,
    required List<PlatformTracking> platformTracking,
    required List<PlatformTracking> cancelledPlatformTracking, // Add this
    required List<BestDeal> bestDeals,
    required int totalTrackedProducts,
    required int activeAlerts,
    required int triggeredAlerts,
    required int cancelledAlerts, // Add this
    required double potentialSavings,
    String? selectedPlatform,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  
  const factory PriceTrackingState.error({
    required String message,
    String? cachedEmail,
  }) = _Error;
  
  const factory PriceTrackingState.creatingAlert() = _CreatingAlert;
  
  const factory PriceTrackingState.alertCreated({
    required String productName,
    required double targetPrice,
  }) = _AlertCreated;
  
  const factory PriceTrackingState.updating() = _Updating;
}

extension PriceTrackingStateX on PriceTrackingState {
  bool get isLoaded => this is _Loaded;
  bool get isLoading => this is _Loading || this is _CreatingAlert || this is _Updating;
  bool get hasError => this is _Error;
  _Loaded? get asLoaded => this is _Loaded ? this as _Loaded : null;
  _Error? get asError => this is _Error ? this as _Error : null;
  
  String? get safeCachedEmail {
    return switch (this) {
      _Loaded(cachedEmail: final email) => email,
      _Error(cachedEmail: final email) => email,
      _ => null,
    };
  }
}

extension LoadedStateX on _Loaded {
  _Loaded updateCachedEmail(String? email) => copyWith(cachedEmail: email);
  _Loaded updatePlatformTracking(List<PlatformTracking> tracking) => copyWith(platformTracking: tracking);
  _Loaded updateCancelledPlatformTracking(List<PlatformTracking> tracking) => copyWith(cancelledPlatformTracking: tracking);
  _Loaded updateBestDeals(List<BestDeal> deals) => copyWith(bestDeals: deals);
  _Loaded updateSelectedPlatform(String? platform) => copyWith(selectedPlatform: platform);
  _Loaded setRefreshing(bool refreshing) => copyWith(isRefreshing: refreshing);
}