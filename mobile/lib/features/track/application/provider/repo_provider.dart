import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/data/api/dio_client.dart';
import 'package:mobile/features/track/data/api/price_tracking_api.dart';
// import 'package:mobile/features/track/data/model/dummy_data_model.dart';
import 'package:mobile/features/track/data/model/price_tracking_model.dart';
// import '../models/price_tracking_model.dart';
// import '../data/dummy_price_data.dart';


final priceTrackingApi = Provider<PriceTrackingApi>((ref)=> PriceTrackingApi(ref.read(dioClientProvider)));

final selectedTabProvider = StateProvider<int>((ref) => 0);
