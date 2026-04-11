import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_payload.freezed.dart';
part 'notification_payload.g.dart';

@freezed
class NotificationPayload with _$NotificationPayload {
  const factory NotificationPayload({
    required String title,
    required String body,
    @JsonKey(name: 'fcm_token') required String fcmToken,
    @Default({}) Map<String, dynamic> data,
  }) = _NotificationPayload;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadFromJson(json);
}

@freezed
class NotificationResponse with _$NotificationResponse {
  const factory NotificationResponse({
    required bool success,
    String? message,
    @Default({}) Map<String, dynamic> data,
  }) = _NotificationResponse;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);
}