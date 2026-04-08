import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/service/web_socket_service.dart';
import 'package:mobile/core/share/data/api/app_state_api.dart';
import 'package:mobile/core/share/data/api/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repo/repo.dart';
import '../../data/repo/storage_service.dart';
import '../../domain/repo.dart';

final sharedPreferenceProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final appStorageProvider = Provider<StorageRepo>(
  (ref) => StorageRepoImpl(ref.read(sharedPreferenceProvider)),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.read(appStorageProvider)),
);

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(baseUrl: 'ws://10.0.2.2:8000');
});


final appStateApiProvider = Provider<AppStateApi>((ref)=> AppStateApi(ref.read(dioClientProvider)));