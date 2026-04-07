// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  int get rank => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_name')
  String get productName => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_platform')
  String get sourcePlatform => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  @JsonKey(name: 'review_count')
  int get reviewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'sentiment_score')
  double get sentimentScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'recommendation_score')
  double get recommendationScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_url')
  String get productUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    int rank,
    @JsonKey(name: 'product_name') String productName,
    @JsonKey(name: 'source_platform') String sourcePlatform,
    double price,
    String currency,
    double rating,
    @JsonKey(name: 'review_count') int reviewCount,
    @JsonKey(name: 'sentiment_score') double sentimentScore,
    @JsonKey(name: 'recommendation_score') double recommendationScore,
    @JsonKey(name: 'product_url') String productUrl,
    @JsonKey(name: 'image_url') String imageUrl,
  });
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? productName = null,
    Object? sourcePlatform = null,
    Object? price = null,
    Object? currency = null,
    Object? rating = null,
    Object? reviewCount = null,
    Object? sentimentScore = null,
    Object? recommendationScore = null,
    Object? productUrl = null,
    Object? imageUrl = null,
  }) {
    return _then(
      _value.copyWith(
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int,
            productName: null == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String,
            sourcePlatform: null == sourcePlatform
                ? _value.sourcePlatform
                : sourcePlatform // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            reviewCount: null == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            sentimentScore: null == sentimentScore
                ? _value.sentimentScore
                : sentimentScore // ignore: cast_nullable_to_non_nullable
                      as double,
            recommendationScore: null == recommendationScore
                ? _value.recommendationScore
                : recommendationScore // ignore: cast_nullable_to_non_nullable
                      as double,
            productUrl: null == productUrl
                ? _value.productUrl
                : productUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int rank,
    @JsonKey(name: 'product_name') String productName,
    @JsonKey(name: 'source_platform') String sourcePlatform,
    double price,
    String currency,
    double rating,
    @JsonKey(name: 'review_count') int reviewCount,
    @JsonKey(name: 'sentiment_score') double sentimentScore,
    @JsonKey(name: 'recommendation_score') double recommendationScore,
    @JsonKey(name: 'product_url') String productUrl,
    @JsonKey(name: 'image_url') String imageUrl,
  });
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? productName = null,
    Object? sourcePlatform = null,
    Object? price = null,
    Object? currency = null,
    Object? rating = null,
    Object? reviewCount = null,
    Object? sentimentScore = null,
    Object? recommendationScore = null,
    Object? productUrl = null,
    Object? imageUrl = null,
  }) {
    return _then(
      _$ProductImpl(
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int,
        productName: null == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String,
        sourcePlatform: null == sourcePlatform
            ? _value.sourcePlatform
            : sourcePlatform // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        reviewCount: null == reviewCount
            ? _value.reviewCount
            : reviewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        sentimentScore: null == sentimentScore
            ? _value.sentimentScore
            : sentimentScore // ignore: cast_nullable_to_non_nullable
                  as double,
        recommendationScore: null == recommendationScore
            ? _value.recommendationScore
            : recommendationScore // ignore: cast_nullable_to_non_nullable
                  as double,
        productUrl: null == productUrl
            ? _value.productUrl
            : productUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl({
    required this.rank,
    @JsonKey(name: 'product_name') required this.productName,
    @JsonKey(name: 'source_platform') required this.sourcePlatform,
    required this.price,
    required this.currency,
    required this.rating,
    @JsonKey(name: 'review_count') required this.reviewCount,
    @JsonKey(name: 'sentiment_score') required this.sentimentScore,
    @JsonKey(name: 'recommendation_score') required this.recommendationScore,
    @JsonKey(name: 'product_url') required this.productUrl,
    @JsonKey(name: 'image_url') required this.imageUrl,
  });

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final int rank;
  @override
  @JsonKey(name: 'product_name')
  final String productName;
  @override
  @JsonKey(name: 'source_platform')
  final String sourcePlatform;
  @override
  final double price;
  @override
  final String currency;
  @override
  final double rating;
  @override
  @JsonKey(name: 'review_count')
  final int reviewCount;
  @override
  @JsonKey(name: 'sentiment_score')
  final double sentimentScore;
  @override
  @JsonKey(name: 'recommendation_score')
  final double recommendationScore;
  @override
  @JsonKey(name: 'product_url')
  final String productUrl;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;

  @override
  String toString() {
    return 'Product(rank: $rank, productName: $productName, sourcePlatform: $sourcePlatform, price: $price, currency: $currency, rating: $rating, reviewCount: $reviewCount, sentimentScore: $sentimentScore, recommendationScore: $recommendationScore, productUrl: $productUrl, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.sourcePlatform, sourcePlatform) ||
                other.sourcePlatform == sourcePlatform) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.sentimentScore, sentimentScore) ||
                other.sentimentScore == sentimentScore) &&
            (identical(other.recommendationScore, recommendationScore) ||
                other.recommendationScore == recommendationScore) &&
            (identical(other.productUrl, productUrl) ||
                other.productUrl == productUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    rank,
    productName,
    sourcePlatform,
    price,
    currency,
    rating,
    reviewCount,
    sentimentScore,
    recommendationScore,
    productUrl,
    imageUrl,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(this);
  }
}

abstract class _Product implements Product {
  const factory _Product({
    required final int rank,
    @JsonKey(name: 'product_name') required final String productName,
    @JsonKey(name: 'source_platform') required final String sourcePlatform,
    required final double price,
    required final String currency,
    required final double rating,
    @JsonKey(name: 'review_count') required final int reviewCount,
    @JsonKey(name: 'sentiment_score') required final double sentimentScore,
    @JsonKey(name: 'recommendation_score')
    required final double recommendationScore,
    @JsonKey(name: 'product_url') required final String productUrl,
    @JsonKey(name: 'image_url') required final String imageUrl,
  }) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  int get rank;
  @override
  @JsonKey(name: 'product_name')
  String get productName;
  @override
  @JsonKey(name: 'source_platform')
  String get sourcePlatform;
  @override
  double get price;
  @override
  String get currency;
  @override
  double get rating;
  @override
  @JsonKey(name: 'review_count')
  int get reviewCount;
  @override
  @JsonKey(name: 'sentiment_score')
  double get sentimentScore;
  @override
  @JsonKey(name: 'recommendation_score')
  double get recommendationScore;
  @override
  @JsonKey(name: 'product_url')
  String get productUrl;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
