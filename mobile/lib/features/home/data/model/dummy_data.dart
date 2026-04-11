
import 'package:mobile/features/home/data/model/news_model.dart';


class DummyData {
  static List<News> getNews() {
    return [
      News(
        id: '1',
        title: '🔥 Price Alert: iPhone 15 Pro Max',
        content: 'Price dropped by 15% on Amazon! Limited time offer.',
        imageUrl: 'https://picsum.photos/400/200?random=1',
        publishedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NewsType.priceAlert,
      ),
      News(
        id: '2',
        title: '📊 Market Trend: Gaming Laptops',
        content: 'Gaming laptop prices expected to rise next month due to new releases.',
        imageUrl: 'https://picsum.photos/400/200?random=2',
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
        type: NewsType.marketTrend,
      ),
      News(
        id: '3',
        title: '🎉 New Product: Samsung Galaxy S24',
        content: 'Pre-order now with exclusive discounts!',
        imageUrl: 'https://picsum.photos/400/200?random=3',
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        type: NewsType.newProduct,
      ),
      News(
        id: '4',
        title: '💡 Pro Tip: Price Tracking',
        content: 'Set price alerts to never miss a deal!',
        imageUrl: 'https://picsum.photos/400/200?random=4',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NewsType.tip,
      ),
    ];
  }

 
}

// fb4a0d4f96aec097cfb4b7c44a76b9d2