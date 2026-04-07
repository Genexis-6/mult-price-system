import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required int rank,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'source_platform') required String sourcePlatform,
    required double price,
    required String currency,
    required double rating,
    @JsonKey(name: 'review_count') required int reviewCount,
    @JsonKey(name: 'sentiment_score') required double sentimentScore,
    @JsonKey(name: 'recommendation_score') required double recommendationScore,
    @JsonKey(name: 'product_url') required String productUrl,
    @JsonKey(name: 'image_url') required String imageUrl,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}