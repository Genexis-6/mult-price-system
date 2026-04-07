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

// Extension must be OUTSIDE the class
extension HomeStateExtension on HomeState {
  bool get isTaskCompleted => this is _TaskCompleted;
  bool get isTaskFailed => this is _TaskFailed;
  bool get isTaskProcessing => this is _TaskProcessing;
  bool get isTaskCreated => this is _TaskCreated;
  bool get isReconnecting => this is _Reconnecting;
  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isError => this is _Error;
}