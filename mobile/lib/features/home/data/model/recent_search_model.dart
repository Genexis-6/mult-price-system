import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_search_model.freezed.dart';
part 'recent_search_model.g.dart';

@freezed
class RecentSearch with _$RecentSearch {
  const factory RecentSearch({
    required String query,
    required DateTime timestamp,
    @Default(0) int resultCount,
  }) = _RecentSearch;

  factory RecentSearch.fromJson(Map<String, dynamic> json) => _$RecentSearchFromJson(json);
}