// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      rank: (json['rank'] as num).toInt(),
      productName: json['product_name'] as String,
      sourcePlatform: json['source_platform'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num).toInt(),
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      recommendationScore: (json['recommendation_score'] as num).toDouble(),
      productUrl: json['product_url'] as String,
      imageUrl: json['image_url'] as String,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'product_name': instance.productName,
      'source_platform': instance.sourcePlatform,
      'price': instance.price,
      'currency': instance.currency,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'sentiment_score': instance.sentimentScore,
      'recommendation_score': instance.recommendationScore,
      'product_url': instance.productUrl,
      'image_url': instance.imageUrl,
    };
