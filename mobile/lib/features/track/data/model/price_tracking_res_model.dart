import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_tracking_res_model.freezed.dart';
part 'price_tracking_res_model.g.dart';

// MARK: - Enums
enum AlertStatus {
  @JsonValue('active')
  active,
  @JsonValue('triggered')
  triggered,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled;
}

// MARK: - Create Price Alert Model
@freezed
class CreatePriceAlertModel with _$CreatePriceAlertModel {
  const factory CreatePriceAlertModel({
    required String email,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'target_price') required double targetPrice,
  }) = _CreatePriceAlertModel;

  factory CreatePriceAlertModel.fromJson(Map<String, dynamic> json) =>
      _$CreatePriceAlertModelFromJson(json);
}

// MARK: - Update Price Alert Model
@freezed
class UpdatePriceAlertModel with _$UpdatePriceAlertModel {
  const factory UpdatePriceAlertModel({
    @JsonKey(name: 'target_price') double? targetPrice,
    AlertStatus? status,
  }) = _UpdatePriceAlertModel;

  factory UpdatePriceAlertModel.fromJson(Map<String, dynamic> json) =>
      _$UpdatePriceAlertModelFromJson(json);
}

// MARK: - Price Alert Response
@freezed
class PriceAlertResponse with _$PriceAlertResponse {
  const factory PriceAlertResponse({
    required int id,
    @Default('') String email,  // Default value since API doesn't return it
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'target_price') required double targetPrice,
    @JsonKey(name: 'current_best_price') double? currentBestPrice,
    @JsonKey(name: 'current_best_platform') String? currentBestPlatform,
    required String status,
    @JsonKey(name: 'notification_sent') @Default(false) bool notificationSent,  // Default value
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,  // Make nullable since API doesn't return it
  }) = _PriceAlertResponse;

  factory PriceAlertResponse.fromJson(Map<String, dynamic> json) =>
      _$PriceAlertResponseFromJson(json);
}

// MARK: - Price History Response
@freezed
class PriceHistoryResponse with _$PriceHistoryResponse {
  const factory PriceHistoryResponse({
    required int id,
    required String platform,
    required double price,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'checked_at') required DateTime checkedAt,
  }) = _PriceHistoryResponse;

  factory PriceHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$PriceHistoryResponseFromJson(json);
}

// MARK: - Price Comparison Response
@freezed
class PriceComparisonResponse with _$PriceComparisonResponse {
  const factory PriceComparisonResponse({
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'target_price') required double targetPrice,
    @JsonKey(name: 'current_best_price') required double currentBestPrice,
    @JsonKey(name: 'current_best_platform') required String currentBestPlatform,
    @JsonKey(name: 'current_best_url') required String currentBestUrl,
    required double savings,
    @JsonKey(name: 'savings_percentage') required double savingsPercentage,
    @JsonKey(name: 'all_platform_prices') required List<PlatformPrice> allPlatformPrices,
    required DateTime timestamp,
  }) = _PriceComparisonResponse;

  factory PriceComparisonResponse.fromJson(Map<String, dynamic> json) =>
      _$PriceComparisonResponseFromJson(json);
}

// MARK: - Platform Price
@freezed
class PlatformPrice with _$PlatformPrice {
  const factory PlatformPrice({
    required String platform,
    required double price,
    required String url,
    @JsonKey(name: 'in_stock') required bool inStock,
    @JsonKey(name: 'last_updated') required DateTime lastUpdated,
  }) = _PlatformPrice;

  factory PlatformPrice.fromJson(Map<String, dynamic> json) =>
      _$PlatformPriceFromJson(json);
}

// MARK: - API Response Wrappers
@freezed
class CreateAlertApiResponse with _$CreateAlertApiResponse {
  const factory CreateAlertApiResponse({
    required bool success,
    required String message,
    required CreateAlertData data,
  }) = _CreateAlertApiResponse;

  factory CreateAlertApiResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateAlertApiResponseFromJson(json);
}

@freezed
class CreateAlertData with _$CreateAlertData {
  const factory CreateAlertData({
    @JsonKey(name: 'alert_id') required int alertId,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'target_price') required double targetPrice,
  }) = _CreateAlertData;

  factory CreateAlertData.fromJson(Map<String, dynamic> json) =>
      _$CreateAlertDataFromJson(json);
}

@freezed
class GetUserAlertsApiResponse with _$GetUserAlertsApiResponse {
  const factory GetUserAlertsApiResponse({
    required bool success,
    required List<PriceAlertResponse> data,
  }) = _GetUserAlertsApiResponse;

  factory GetUserAlertsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$GetUserAlertsApiResponseFromJson(json);
}

@freezed
class CancelAlertApiResponse with _$CancelAlertApiResponse {
  const factory CancelAlertApiResponse({
    required bool success,
    required String message,
  }) = _CancelAlertApiResponse;

  factory CancelAlertApiResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelAlertApiResponseFromJson(json);
}

@freezed
class TriggerCheckApiResponse with _$TriggerCheckApiResponse {
  const factory TriggerCheckApiResponse({
    required bool success,
    required String message,
    @JsonKey(name: 'task_id') required String taskId,
  }) = _TriggerCheckApiResponse;

  factory TriggerCheckApiResponse.fromJson(Map<String, dynamic> json) =>
      _$TriggerCheckApiResponseFromJson(json);
}