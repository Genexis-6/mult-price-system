// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskStatusImpl _$$TaskStatusImplFromJson(Map<String, dynamic> json) =>
    _$TaskStatusImpl(
      taskId: json['taskId'] as String,
      status: json['status'] as String? ?? 'processing',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      result: json['result'] ?? null,
    );

Map<String, dynamic> _$$TaskStatusImplToJson(_$TaskStatusImpl instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'status': instance.status,
      'progress': instance.progress,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'result': instance.result,
    };
