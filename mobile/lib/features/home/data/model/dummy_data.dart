import 'package:mobile/core/share/data/model/product_model.dart';
import 'package:mobile/features/home/data/model/news_model.dart';
import 'package:mobile/features/home/data/model/recent_search_model.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';


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

  static List<RecentSearch> getRecentSearches() {
    return [
      RecentSearch(query: 'iPhone 15 Pro Max', timestamp: DateTime.now(), resultCount: 156),
      RecentSearch(query: 'Samsung Galaxy S24', timestamp: DateTime.now(), resultCount: 89),
      RecentSearch(query: 'Gaming Laptop', timestamp: DateTime.now(), resultCount: 234),
      RecentSearch(query: 'Wireless Earbuds', timestamp: DateTime.now(), resultCount: 67),
      RecentSearch(query: 'Smart Watch', timestamp: DateTime.now(), resultCount: 123),
    ];
  }

  static TaskStatus getActiveTask() {
    return TaskStatus(
      taskId: 'task_123',
      status: 'processing',
      progress: 65,
      message: 'Analyzing customer reviews and comparing prices...',
      timestamp: DateTime.now(),
    );
  }

  static List<Product> getFeaturedProducts() {
    return [
      Product(
        id: '1',
        name: 'iPhone 15 Pro Max',
        price: 1199.99,
        originalPrice: 1399.99,
        platform: 'Amazon',
        rating: 4.8,
        reviewCount: 1245,
        imageUrl: 'https://picsum.photos/200/200?random=5',
        sentimentScore: 0.92,
      ),
      Product(
        id: '2',
        name: 'Samsung Galaxy S24 Ultra',
        price: 1299.99,
        originalPrice: 1399.99,
        platform: 'Best Buy',
        rating: 4.7,
        reviewCount: 892,
        imageUrl: 'https://picsum.photos/200/200?random=6',
        sentimentScore: 0.88,
      ),
      Product(
        id: '3',
        name: 'MacBook Pro M3',
        price: 1999.99,
        originalPrice: 2199.99,
        platform: 'Apple Store',
        rating: 4.9,
        reviewCount: 3456,
        imageUrl: 'https://picsum.photos/200/200?random=7',
        sentimentScore: 0.95,
      ),
      Product(
        id: '4',
        name: 'Sony WH-1000XM5',
        price: 349.99,
        originalPrice: 399.99,
        platform: 'Walmart',
        rating: 4.6,
        reviewCount: 789,
        imageUrl: 'https://picsum.photos/200/200?random=8',
        sentimentScore: 0.85,
      ),
    ];
  }

  static Map<String, dynamic> getStats() {
    return {
      'totalProducts': 12500,
      'priceAlerts': 342,
      'activeComparisons': 12,
      'savingsToday': 3450.50,
    };
  }
}