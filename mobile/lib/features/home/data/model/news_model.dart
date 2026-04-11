import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_model.freezed.dart';
part 'news_model.g.dart';

@freezed
class News with _$News {
  const factory News({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    required DateTime publishedAt,
    required NewsType type,
    String? source,
    String? url,
  }) = _News;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
}

enum NewsType {
  priceAlert,
  marketTrend,
  newProduct,
  tip,
}