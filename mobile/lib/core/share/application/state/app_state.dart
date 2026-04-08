import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_state.freezed.dart';

@freezed
class AppState with _$AppState {
  const factory AppState.initial() = _Initial;
  const factory AppState.loading() = _Loading;
  const factory AppState.registered({
    required String fcmToken,
    required int deviceId,
    @Default(false) bool isNewDevice,
  }) = _Registered;
  const factory AppState.error({
    required String message,
  }) = _Error;
  const factory AppState.tokenRefreshing({
    required String oldToken,
    required String newToken,
  }) = _TokenRefreshing;

  const AppState._();
}

// Extension for type checking and helper methods
extension AppStateExtension on AppState {
  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isRegistered => this is _Registered;
  bool get isError => this is _Error;
  bool get isTokenRefreshing => this is _TokenRefreshing;
  
  String? get fcmToken {
    return whenOrNull(
      registered: (fcmToken, _, _) => fcmToken,
      tokenRefreshing: (_, newToken) => newToken,
    );
  }
  
  int? get deviceId {
    return whenOrNull(
      registered: (_, deviceId, _) => deviceId,
    );
  }
  
  String? get errorMessage {
    return whenOrNull(
      error: (message) => message,
    );
  }
}