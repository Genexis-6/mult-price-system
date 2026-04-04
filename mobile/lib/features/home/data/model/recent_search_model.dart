class RecentSearch {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  RecentSearch({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });
}