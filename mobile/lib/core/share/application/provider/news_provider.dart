import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/core/share/data/api/dio_client.dart';
import 'package:mobile/core/share/data/api/news_api.dart';
// import 'package:mobile/features/home/data/api/news_api.dart';
import 'package:mobile/features/home/data/model/news_model.dart';

final newsApiProvider = Provider<NewsApiService>((ref) {
  final dio = ref.read(dioClientProvider);
  return NewsApiService(dio);
});

final topHeadlinesProvider = FutureProvider<List<News>>((ref) async {
  final api = ref.read(newsApiProvider);
  // Try to get tech news first as they're more interesting
  final techNews = await api.fetchTechNews();
  if (techNews.isNotEmpty) {
    return techNews;
  }
  // Fallback to general US news
  return await api.fetchTopHeadlines(country: 'us');
});

final businessNewsProvider = FutureProvider<List<News>>((ref) async {
  final api = ref.read(newsApiProvider);
  return await api.fetchBusinessNews();
});

final technologyNewsProvider = FutureProvider<List<News>>((ref) async {
  final api = ref.read(newsApiProvider);
  return await api.fetchTechNews();
});

final productNewsProvider = FutureProvider.family<List<News>, String>((ref, productName) async {
  final api = ref.read(newsApiProvider);
  return await api.fetchProductNews(productName);
});