// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskStatus _$TaskStatusFromJson(Map<String, dynamic> json) {
  return _TaskStatus.fromJson(json);
}

/// @nodoc
mixin _$TaskStatus {
  String get taskId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  dynamic get result => throw _privateConstructorUsedError;

  /// Serializes this TaskStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskStatusCopyWith<TaskStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskStatusCopyWith<$Res> {
  factory $TaskStatusCopyWith(
    TaskStatus value,
    $Res Function(TaskStatus) then,
  ) = _$TaskStatusCopyWithImpl<$Res, TaskStatus>;
  @useResult
  $Res call({
    String taskId,
    String status,
    int progress,
    String message,
    DateTime timestamp,
    dynamic result,
  });
}

/// @nodoc
class _$TaskStatusCopyWithImpl<$Res, $Val extends TaskStatus>
    implements $TaskStatusCopyWith<$Res> {
  _$TaskStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? status = null,
    Object? progress = null,
    Object? message = null,
    Object? timestamp = null,
    Object? result = freezed,
  }) {
    return _then(
      _value.copyWith(
            taskId: null == taskId
                ? _value.taskId
                : taskId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as int,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            result: freezed == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as dynamic,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskStatusImplCopyWith<$Res>
    implements $TaskStatusCopyWith<$Res> {
  factory _$$TaskStatusImplCopyWith(
    _$TaskStatusImpl value,
    $Res Function(_$TaskStatusImpl) then,
  ) = __$$TaskStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String taskId,
    String status,
    int progress,
    String message,
    DateTime timestamp,
    dynamic result,
  });
}

/// @nodoc
class __$$TaskStatusImplCopyWithImpl<$Res>
    extends _$TaskStatusCopyWithImpl<$Res, _$TaskStatusImpl>
    implements _$$TaskStatusImplCopyWith<$Res> {
  __$$TaskStatusImplCopyWithImpl(
    _$TaskStatusImpl _value,
    $Res Function(_$TaskStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? status = null,
    Object? progress = null,
    Object? message = null,
    Object? timestamp = null,
    Object? result = freezed,
  }) {
    return _then(
      _$TaskStatusImpl(
        taskId: null == taskId
            ? _value.taskId
            : taskId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        result: freezed == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskStatusImpl implements _TaskStatus {
  const _$TaskStatusImpl({
    required this.taskId,
    this.status = 'processing',
    this.progress = 0,
    this.message = '',
    required this.timestamp,
    this.result = null,
  });

  factory _$TaskStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskStatusImplFromJson(json);

  @override
  final String taskId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int progress;
  @override
  @JsonKey()
  final String message;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final dynamic result;

  @override
  String toString() {
    return 'TaskStatus(taskId: $taskId, status: $status, progress: $progress, message: $message, timestamp: $timestamp, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskStatusImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other.result, result));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    taskId,
    status,
    progress,
    message,
    timestamp,
    const DeepCollectionEquality().hash(result),
  );

  /// Create a copy of TaskStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskStatusImplCopyWith<_$TaskStatusImpl> get copyWith =>
      __$$TaskStatusImplCopyWithImpl<_$TaskStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskStatusImplToJson(this);
  }
}

abstract class _TaskStatus implements TaskStatus {
  const factory _TaskStatus({
    required final String taskId,
    final String status,
    final int progress,
    final String message,
    required final DateTime timestamp,
    final dynamic result,
  }) = _$TaskStatusImpl;

  factory _TaskStatus.fromJson(Map<String, dynamic> json) =
      _$TaskStatusImpl.fromJson;

  @override
  String get taskId;
  @override
  String get status;
  @override
  int get progress;
  @override
  String get message;
  @override
  DateTime get timestamp;
  @override
  dynamic get result;

  /// Create a copy of TaskStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskStatusImplCopyWith<_$TaskStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
