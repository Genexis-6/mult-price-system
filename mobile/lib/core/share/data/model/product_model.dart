class Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final String platform;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double sentimentScore;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.platform,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.sentimentScore,
  });

  double get discountPercentage {
    if (originalPrice == null) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedOriginalPrice => originalPrice != null ? '\$${originalPrice!.toStringAsFixed(2)}' : '';
}