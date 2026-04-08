import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_model.freezed.dart';
part 'device_model.g.dart';

@freezed
class Device with _$Device {
  const factory Device({
    @JsonKey(name: 'device_id') required int deviceId,
    @JsonKey(name: 'fcm_token') required String fcmToken,
    @JsonKey(name: 'is_new') @Default(false) bool isNew,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

@freezed
class DeviceTask with _$DeviceTask {
  const factory DeviceTask({
    required String taskId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _DeviceTask;

  factory DeviceTask.fromJson(Map<String, dynamic> json) =>
      _$DeviceTaskFromJson(json);
}
