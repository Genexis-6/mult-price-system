import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile/features/home/data/model/news_model.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

class NewsApiService {
  final Dio _dio;
  static const String baseUrl = 'https://newsapi.org/v2';
  
  static String get apiKey {
    final key = dotenv.env['NEWS_API_KEY'];
    if (key == null || key.isEmpty) {
      logger.w("⚠️ NEWS_API_KEY not found in .env file. News features will be limited.");
      return '';
    }
    return key;
  }

  NewsApiService(this._dio);

  Future<List<News>> fetchTopHeadlines({
    String? country = 'us', // Changed from 'ng' to 'us' for more articles
    String? category,
    int pageSize = 20,
    String? query, // Added query parameter for better results
  }) async {
    if (apiKey.isEmpty) {
      logger.w("⚠️ Cannot fetch news: API key missing");
      return _getFallbackNews();
    }

    try {
      final queryParams = {
        'apiKey': apiKey,
        'country': country,
        'pageSize': pageSize,
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final response = await _dio.get(
        '$baseUrl/top-headlines',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final articles = response.data['articles'] as List;
        if (articles.isEmpty) {
          logger.w("No articles found for country: $country, trying with 'us'");
          // Retry with US if no articles found
          return await _fetchUSHeadlines(pageSize);
        }
        final newsList = articles.map((article) => _convertToNews(article)).toList();
        logger.d("✅ Fetched ${newsList.length} news articles");
        return newsList;
      }
      return _getFallbackNews();
    } catch (e) {
      logger.e("❌ Error fetching news: $e");
      return _getFallbackNews();
    }
  }

  Future<List<News>> _fetchUSHeadlines(int pageSize) async {
    try {
      final response = await _dio.get(
        '$baseUrl/top-headlines',
        queryParameters: {
          'apiKey': apiKey,
          'country': 'us',
          'pageSize': pageSize,
        },
      );
      
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final articles = response.data['articles'] as List;
        final newsList = articles.map((article) => _convertToNews(article)).toList();
        logger.d("✅ Fetched ${newsList.length} news articles from US");
        return newsList;
      }
      return _getFallbackNews();
    } catch (e) {
      logger.e("❌ Error fetching US news: $e");
      return _getFallbackNews();
    }
  }

  Future<List<News>> fetchTechNews() async {
    return await fetchTopHeadlines(
      country: 'us',
      category: 'technology',
      pageSize: 20,
    );
  }

  Future<List<News>> fetchBusinessNews() async {
    return await fetchTopHeadlines(
      country: 'us',
      category: 'business',
      pageSize: 20,
    );
  }

  Future<List<News>> fetchProductNews(String productName) async {
    return await fetchTopHeadlines(
      country: 'us',
      query: productName,
      pageSize: 10,
    );
  }

  Future<List<News>> searchNews(String query, {int pageSize = 20}) async {
    if (apiKey.isEmpty) {
      logger.w("⚠️ Cannot search news: API key missing");
      return _getFallbackNews();
    }

    try {
      final response = await _dio.get(
        '$baseUrl/everything',
        queryParameters: {
          'apiKey': apiKey,
          'q': query,
          'pageSize': pageSize,
          'sortBy': 'publishedAt',
          'language': 'en',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final articles = response.data['articles'] as List;
        if (articles.isEmpty) {
          logger.w("No search results for: $query");
          return _getFallbackNews();
        }
        final newsList = articles.map((article) => _convertToNews(article)).toList();
        logger.d("✅ Found ${newsList.length} news articles for query: $query");
        return newsList;
      }
      return _getFallbackNews();
    } catch (e) {
      logger.e("❌ Error searching news: $e");
      return _getFallbackNews();
    }
  }

  List<News> _getFallbackNews() {
    return [
      News(
        id: '1',
        title: '🔥 Welcome to Mula Search!',
        content: 'Start searching for products across Jumia, Konga, and Jiji to find the best deals.',
        imageUrl: 'https://picsum.photos/400/200?random=1',
        publishedAt: DateTime.now(),
        type: NewsType.tip,
        source: 'Mula Search',
        url: '',
      ),
      News(
        id: '2',
        title: '💡 Pro Tip: Compare Prices',
        content: 'Always compare prices across different platforms to get the best value for your money.',
        imageUrl: 'https://picsum.photos/400/200?random=2',
        publishedAt: DateTime.now(),
        type: NewsType.tip,
        source: 'Mula Search',
        url: '',
      ),
      News(
        id: '3',
        title: '📊 Track Price Drops',
        content: 'Set up price alerts to get notified when your favorite products go on sale.',
        imageUrl: 'https://picsum.photos/400/200?random=3',
        publishedAt: DateTime.now(),
        type: NewsType.priceAlert,
        source: 'Mula Search',
        url: '',
      ),
      News(
        id: '4',
        title: '🎉 New Features Coming Soon',
        content: 'We\'re constantly improving Mula Search. Stay tuned for exciting updates!',
        imageUrl: 'https://picsum.photos/400/200?random=4',
        publishedAt: DateTime.now(),
        type: NewsType.newProduct,
        source: 'Mula Search',
        url: '',
      ),
    ];
  }

  News _convertToNews(Map<String, dynamic> article) {
    final publishedAt = DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now();
    final source = article['source']?['name'] ?? 'Unknown Source';
    final title = article['title'] ?? 'No title';
    
    final newsType = _determineNewsType(title, source);
    
    return News(
      id: article['url']?.hashCode.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: article['description'] ?? article['content'] ?? 'Click to read more...',
      imageUrl: article['urlToImage'] ?? 'https://picsum.photos/400/200',
      publishedAt: publishedAt,
      type: newsType,
      source: source,
      url: article['url'] ?? '',
    );
  }

  NewsType _determineNewsType(String title, String source) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('price') || 
        lowerTitle.contains('deal') || 
        lowerTitle.contains('offer') ||
        lowerTitle.contains('sale') ||
        lowerTitle.contains('discount')) {
      return NewsType.priceAlert;
    }
    
    if (lowerTitle.contains('trend') || 
        lowerTitle.contains('market') || 
        lowerTitle.contains('forecast') ||
        source.toLowerCase().contains('business')) {
      return NewsType.marketTrend;
    }
    
    if (lowerTitle.contains('new') || 
        lowerTitle.contains('launch') || 
        lowerTitle.contains('release') ||
        lowerTitle.contains('announce')) {
      return NewsType.newProduct;
    }
    
    return NewsType.tip;
  }
}