class News {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime publishedAt;
  final NewsType type;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.publishedAt,
    required this.type,
  });
}

enum NewsType {
  priceAlert,
  marketTrend,
  newProduct,
  tip,
}