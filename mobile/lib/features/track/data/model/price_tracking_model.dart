import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/core/josn_converter/icon_converter.dart';

part 'price_tracking_model.freezed.dart';
part 'price_tracking_model.g.dart';



@freezed
class TrackedProduct with _$TrackedProduct {
  const factory TrackedProduct({
    required String id,
    required String productName,
    required double targetPrice,
    double? currentPrice,
    required String platform,
    required double priceDifference,
    required bool isTargetReached,
    required DateTime lastChecked,
    String? productUrl,
    String? status,
    @Default([]) List<PriceHistory> priceHistory,
  }) = _TrackedProduct;

  factory TrackedProduct.fromJson(Map<String, dynamic> json) =>
      _$TrackedProductFromJson(json);
}


@freezed
class PriceHistory with _$PriceHistory {
  const factory PriceHistory({
    required DateTime date,
    required double price,
    required String platform,
  }) = _PriceHistory;

  factory PriceHistory.fromJson(Map<String, dynamic> json) => _$PriceHistoryFromJson(json);
}


@freezed
class BestDeal with _$BestDeal {
  const factory BestDeal({
    required String id,
    required String productName,
    required double price,
    required double targetPrice,
    required String platform,
    required double savings,
    required double savingsPercentage,
    required DateTime triggeredAt,
    String? productUrl,
  }) = _BestDeal;

  factory BestDeal.fromJson(Map<String, dynamic> json) =>
      _$BestDealFromJson(json);
}

@freezed
class PlatformTracking with _$PlatformTracking {
  const factory PlatformTracking({
    required String platform,
    required List<TrackedProduct> products,
    required int activeAlerts,
    required int triggeredAlerts,
    @JsonKey(
      fromJson: _colorFromJson,
      toJson: _colorToJson,
    )
    required Color platformColor,

    
    @IconDataConverter()
    required IconData platformIcon,
  }) = _PlatformTracking;

  factory PlatformTracking.fromJson(Map<String, dynamic> json) => _$PlatformTrackingFromJson(json);
}

Color _colorFromJson(int value) => Color(value);
int _colorToJson(Color color) => color.value;