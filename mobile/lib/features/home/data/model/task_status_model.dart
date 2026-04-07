import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_status_model.freezed.dart';
part 'task_status_model.g.dart';

@freezed
class TaskStatus with _$TaskStatus {
  const factory TaskStatus({
    required String taskId,
    @Default('processing') String status,
    @Default(0) int progress,
    @Default('') String message,
    required DateTime timestamp,
    @Default(null) dynamic result,
  }) = _TaskStatus;

  factory TaskStatus.fromJson(Map<String, dynamic> json) => _$TaskStatusFromJson(json);
}