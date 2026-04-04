import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/data/api/dio_client.dart';
import 'package:mobile/features/home/data/api/home_api.dart';

final homeApiProvider = Provider<HomeApi>(
  (ref) => HomeApi(ref.read(dioClientProvider)),
);
