import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/domain/repo.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/features/home/data/model/recent_search_model.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<RecentSearch>>(
  (ref) => RecentSearchesNotifier(ref.read(appStorageProvider)),
);

class RecentSearchesNotifier extends StateNotifier<List<RecentSearch>> {
  final StorageRepo _storageRepo;
  static const String _recentSearchesKey = 'recent_searches';
  static const int maxRecentSearches = 10;

  RecentSearchesNotifier(this._storageRepo) : super([]) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      // Use getStringList instead of get<List<String>>
      final searchesJson = _storageRepo.getStringList(key: _recentSearchesKey);
      
      if (searchesJson != null && searchesJson.isNotEmpty) {
        final searches = <RecentSearch>[];
        for (final json in searchesJson) {
          try {
            final search = RecentSearch.fromJson(_decodeJson(json));
            searches.add(search);
          } catch (e) {
            logger.e("Error parsing search: $e");
          }
        }
        state = searches;
        logger.d("✅ Loaded ${state.length} recent searches");
      } else {
        state = [];
        logger.d("No recent searches found");
      }
    } catch (e) {
      logger.e("❌ Error loading recent searches: $e");
      state = [];
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final searchesJson = state
          .map((search) => _encodeJson(search.toJson()))
          .toList();
      
      // Save as List<String> using save method with List<String> type
      _storageRepo.save<List<String>>(key: _recentSearchesKey, val: searchesJson);
      logger.d("✅ Saved ${state.length} recent searches");
    } catch (e) {
      logger.e("❌ Error saving recent searches: $e");
    }
  }

  Map<String, dynamic> _decodeJson(String json) {
    try {
      // Try to parse as JSON first (more robust)
      if (json.startsWith('{')) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
      
      // Fallback to pipe-separated format
      final parts = json.split('|');
      return {
        'query': parts[0],
        'timestamp': parts[1],
        'resultCount': int.parse(parts[2]),
      };
    } catch (e) {
      logger.e("Error decoding JSON: $e");
      return {
        'query': '',
        'timestamp': DateTime.now().toIso8601String(),
        'resultCount': 0,
      };
    }
  }

  String _encodeJson(Map<String, dynamic> json) {
    try {
      // Use JSON encoding for better compatibility
      return jsonEncode(json);
    } catch (e) {
      // Fallback to pipe-separated format
      return '${json['query']}|${json['timestamp']}|${json['resultCount']}';
    }
  }

  void addRecentSearch(String query, {int resultCount = 0}) {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    final existingIndex = state.indexWhere((s) => s.query.toLowerCase() == query.toLowerCase());
    final newState = List<RecentSearch>.from(state);
    
    if (existingIndex != -1) {
      newState.removeAt(existingIndex);
    }
    
    // Add new search at the beginning
    newState.insert(0, RecentSearch(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
    ));
    
    // Keep only maxRecentSearches
    if (newState.length > maxRecentSearches) {
      newState.removeRange(maxRecentSearches, newState.length);
    }
    
    state = newState;
    _saveRecentSearches();
    logger.d("✅ Added recent search: $query");
  }

  void removeRecentSearch(String query) {
    final removed = state.where((s) => s.query != query).toList();
    state = removed;
    _saveRecentSearches();
    logger.d("✅ Removed recent search: $query");
  }

  void clearAllRecentSearches() {
    state = [];
    _saveRecentSearches();
    logger.d("✅ Cleared all recent searches");
  }

  void updateResultCount(String query, int resultCount) {
    final index = state.indexWhere((s) => s.query == query);
    if (index != -1) {
      final updatedSearch = state[index].copyWith(resultCount: resultCount);
      final newState = List<RecentSearch>.from(state);
      newState[index] = updatedSearch;
      state = newState;
      _saveRecentSearches();
      logger.d("✅ Updated result count for: $query to $resultCount");
    }
  }

  // Helper method to check if a search exists
  bool contains(String query) {
    return state.any((s) => s.query.toLowerCase() == query.toLowerCase());
  }

  // Get recent searches by time range
  List<RecentSearch> getRecentSearchesByTime({Duration? within}) {
    if (within == null) return state;
    
    final cutoff = DateTime.now().subtract(within);
    return state.where((search) => search.timestamp.isAfter(cutoff)).toList();
  }

  // Get most popular searches (by result count)
  List<RecentSearch> getPopularSearches({int limit = 5}) {
    final sorted = List<RecentSearch>.from(state);
    sorted.sort((a, b) => b.resultCount.compareTo(a.resultCount));
    return sorted.take(limit).toList();
  }
}