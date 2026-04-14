import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.reconnecting({
    required String taskId,
    required String query,
  }) = _Reconnecting;
  const factory HomeState.taskCreated({
    required String taskId,
    required String query,
  }) = _TaskCreated;
  const factory HomeState.taskProcessing({
    required String taskId,
    required String query,
    required int progress,
    required String message,
  }) = _TaskProcessing;
  const factory HomeState.taskCompleted({
    required String taskId,
    required String query,
    required dynamic result,
  }) = _TaskCompleted;
  const factory HomeState.taskFailed({
    required String taskId,
    required String query,
    required String error,
  }) = _TaskFailed;
  const factory HomeState.error({
    required String message,
  }) = _Error;
}

// MARK: - Type Check Extensions
extension HomeStateTypeExtension on HomeState {
  bool get isTaskCompleted => this is _TaskCompleted;
  bool get isTaskFailed => this is _TaskFailed;
  bool get isTaskProcessing => this is _TaskProcessing;
  bool get isTaskCreated => this is _TaskCreated;
  bool get isReconnecting => this is _Reconnecting;
  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isError => this is _Error;
}

// MARK: - Value Access Extensions
extension HomeStateValueExtension on HomeState {
  String? get taskId {
    return whenOrNull(
      reconnecting: (taskId, _) => taskId,
      taskCreated: (taskId, _) => taskId,
      taskProcessing: (taskId, _, _, _) => taskId,
      taskCompleted: (taskId, _, _) => taskId,
      taskFailed: (taskId, _, _) => taskId,
    );
  }
  
  String? get query {
    return whenOrNull(
      reconnecting: (_, query) => query,
      taskCreated: (_, query) => query,
      taskProcessing: (_, query, _, _) => query,
      taskCompleted: (_, query, _) => query,
      taskFailed: (_, query, _) => query,
    );
  }
  
  int? get progress {
    return whenOrNull(
      taskProcessing: (_, _, progress, _) => progress,
    );
  }
  
  String? get message {
    return whenOrNull(
      taskProcessing: (_, _, _, message) => message,
      error: (message) => message,
    );
  }
  
  String? get error {
    return whenOrNull(
      taskFailed: (_, _, error) => error,
      error: (message) => message,
    );
  }
  
  dynamic get result {
    return whenOrNull(
      taskCompleted: (_, _, result) => result,
    );
  }
}

// MARK: - Safe Cast Extensions
extension HomeStateCastExtension on HomeState {
  _Reconnecting? get asReconnecting => this is _Reconnecting ? this as _Reconnecting : null;
  _TaskCreated? get asTaskCreated => this is _TaskCreated ? this as _TaskCreated : null;
  _TaskProcessing? get asTaskProcessing => this is _TaskProcessing ? this as _TaskProcessing : null;
  _TaskCompleted? get asTaskCompleted => this is _TaskCompleted ? this as _TaskCompleted : null;
  _TaskFailed? get asTaskFailed => this is _TaskFailed ? this as _TaskFailed : null;
  _Error? get asError => this is _Error ? this as _Error : null;
}

// MARK: - Helper Methods
extension HomeStateHelperExtension on HomeState {
  bool get hasActiveTask {
    return isTaskCreated || isTaskProcessing || isReconnecting;
  }
  
  bool get isTaskFinished {
    return isTaskCompleted || isTaskFailed;
  }
  
  String get statusText {
    return when(
      initial: () => 'Ready',
      loading: () => 'Loading...',
      reconnecting: (_, __) => 'Reconnecting',
      taskCreated: (_, __) => 'Task Created',
      taskProcessing: (_, __, progress, _) => 'Processing ($progress%)',
      taskCompleted: (_, __, _) => 'Completed',
      taskFailed: (_, __, _) => 'Failed',
      error: (_) => 'Error',
    );
  }
  
  Color get statusColor {
    return when(
      initial: () => const Color(0xFF22C55E), // Green
      loading: () => const Color(0xFF6366F1), // Blue
      reconnecting: (_, __) => const Color(0xFFF59E0B), // Orange
      taskCreated: (_, __) => const Color(0xFF3B82F6), // Blue
      taskProcessing: (_, __, _, _) => const Color(0xFFF59E0B), // Orange
      taskCompleted: (_, __, _) => const Color(0xFF22C55E), // Green
      taskFailed: (_, __, _) => const Color(0xFFEF4444), // Red
      error: (_) => const Color(0xFFEF4444), // Red
    );
  }
}