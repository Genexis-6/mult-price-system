import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/track/data/model/dummy_data_model.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
// import '../models/price_tracking_model.dart';
// import '../data/dummy_price_data.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final platformTrackingProvider = Provider<List<PlatformTracking>>((ref) {
  return DummyPriceData.getPlatformTracking();
});

final bestDealsProvider = Provider<List<BestDeal>>((ref) {
  return DummyPriceData.getBestDeals();
});

final jumiaProductsProvider = Provider<List<TrackedProduct>>((ref) {
  return DummyPriceData.getJumiaTrackedProducts();
});

final kongaProductsProvider = Provider<List<TrackedProduct>>((ref) {
  return DummyPriceData.getKongaTrackedProducts();
});

final jijiProductsProvider = Provider<List<TrackedProduct>>((ref) {
  return DummyPriceData.getJijiTrackedProducts();
});