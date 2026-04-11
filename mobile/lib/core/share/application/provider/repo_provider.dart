import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/share/application/service/web_socket_service.dart';
import 'package:mobile/core/share/application/state/app_state.dart';
import 'package:mobile/core/share/data/api/app_state_api.dart';
import 'package:mobile/core/share/data/api/dio_client.dart';
// import 'package:mobile/core/share/data/api/news_api.dart';
import 'package:mobile/features/home/application/provider/repo_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/app_backgound_updat.dart';
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

final appStateApiProvider = Provider<AppStateApi>(
  (ref) => AppStateApi(ref.read(dioClientProvider)),
);

final appBackgroundUpdateProvider = Provider<AppBackgroundUpdate>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final homeApi = ref.read(homeApiProvider);
  final appStateApi = ref.read(appStateApiProvider);
  final appState = ref.watch(appStateProvider);

  String? fcmToken;
  appState.when(
    data: (state) {
      if (state.isRegistered) {
        fcmToken = state.fcmToken;
      }
    },
    loading: () {},
    error: (_, _) {},
  );

  return AppBackgroundUpdate(
    storageService: storageService,
    homeApi: homeApi,
    appStateApi: appStateApi,
    fcmToken: fcmToken,
  );
});

