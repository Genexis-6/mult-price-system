// home_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/core/share/data/model/response_model.dart';
import 'package:mobile/core/share/data/repo/storage_service.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:mobile/features/home/application/provider/repo_provider.dart';
import 'package:mobile/features/home/application/state/home_state.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';

final homeProvider = AsyncNotifierProvider<HomeProvider, HomeState>(
  () => HomeProvider(),
);

class HomeProvider extends AsyncNotifier<HomeState> {
  StreamSubscription? _webSocketSubscription;
  String? _currentTaskId;
  late StorageService _storageService;
  bool _isReconnecting = false;

  @override
  FutureOr<HomeState> build() async {
    _storageService = ref.read(storageServiceProvider);

    // Check for existing task when app starts
    final lastTask = await _storageService.getLastTask();
    logger.d(lastTask);

    if (lastTask != null) {
      final taskId = lastTask['taskId']!;
      final query = lastTask['query']!;

      try {
        final response = await ref
            .read(homeApiProvider)
            .checkTaskStatus(taskId);

        if (response.success && response.data?['exists'] == true) {
          final status = response.data?['status'];

          if (status == 'PROCESSING' || status == 'pending' || status == 'processing') {
            logger.d('✅ Task $taskId is still processing, reconnecting...');
            state = AsyncValue.data(
              HomeState.reconnecting(taskId: taskId, query: query),
            );
            _connectToWebSocket(taskId, query);
            return HomeState.reconnecting(taskId: taskId, query: query);
          } else if (status == 'SUCCESS' || status == 'completed') {
            logger.d('✅ Task $taskId already completed, showing results');
            final result = response.data?['result'];
            if (result != null) {
              state = AsyncValue.data(
                HomeState.taskCompleted(
                  taskId: taskId,
                  query: query,
                  result: result,
                ),
              );
              await _storageService.clearLastTask();
              return HomeState.taskCompleted(
                taskId: taskId,
                query: query,
                result: result,
              );
            }
          } else if (status == 'FAILED') {
            logger.d('❌ Task $taskId failed');
            state = AsyncValue.data(
              HomeState.taskFailed(
                taskId: taskId,
                query: query,
                error: response.data?['error'] ?? 'Task failed',
              ),
            );
            await _storageService.clearLastTask();
            return HomeState.taskFailed(
              taskId: taskId,
              query: query,
              error: response.data?['error'] ?? 'Task failed',
            );
          } else {
            logger.w('⚠️ Task $taskId has status: $status, clearing...');
            await _storageService.clearLastTask();
          }
        } else {
          logger.w('⚠️ Task $taskId not found on backend, clearing local storage');
          await _storageService.clearLastTask();
        }
      } catch (e) {
        logger.e('❌ Failed to check task status: $e, clearing local storage');
        await _storageService.clearLastTask();
      }
    }

    return const HomeState.initial();
  }

  // ADD THESE TWO METHODS:

  /// Disconnect WebSocket without canceling the task
  void disconnectWebSocket() {
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    logger.d('🔌 HomeProvider: WebSocket disconnected');
  }

  /// Reconnect WebSocket if there's an active task
  Future<void> reconnectWebSocketIfNeeded() async {
    final currentState = state.value;
    if (currentState == null) return;

    final taskId = currentState.maybeWhen(
      taskProcessing: (taskId, _, _, _) => taskId,
      reconnecting: (taskId, _) => taskId,
      taskCreated: (taskId, _) => taskId,
      orElse: () => null,
    );

    final query = currentState.maybeWhen(
      taskProcessing: (_, query, _, _) => query,
      reconnecting: (_, query) => query,
      taskCreated: (_, query) => query,
      orElse: () => null,
    );

    if (taskId != null && query != null && _webSocketSubscription == null) {
      logger.d('🔄 HomeProvider: Reconnecting WebSocket for task: $taskId');
      _connectToWebSocket(taskId, query);
    }
  }

  Future<void> reconnectToTask() async {
    if (_isReconnecting) return;

    final lastTask = await _storageService.getLastTask();
    if (lastTask != null &&
        (_webSocketSubscription == null ||
            _webSocketSubscription?.isPaused == true)) {
      final taskId = lastTask['taskId']!;
      final query = lastTask['query']!;

      logger.d('🔄 Reconnecting to task: $taskId');
      _isReconnecting = true;

      final response = await ref.read(homeApiProvider).checkTaskStatus(taskId);

      if (response.success && response.data?['exists'] == true) {
        final status = response.data?['status'];

        if (status == 'PROCESSING' || status == 'pending') {
          updateState(HomeState.reconnecting(taskId: taskId, query: query));
          _connectToWebSocket(taskId, query);
        } else if (status == 'SUCCESS' || status == 'completed') {
          final result = response.data?['result'];
          if (result != null) {
            updateState(
              HomeState.taskCompleted(
                taskId: taskId,
                query: query,
                result: result,
              ),
            );
            await _storageService.clearLastTask();
          }
        } else if (status == 'FAILED') {
          updateState(
            HomeState.taskFailed(
              taskId: taskId,
              query: query,
              error: response.data?['error'] ?? 'Task failed',
            ),
          );
          await _storageService.clearLastTask();
        }
      }

      _isReconnecting = false;
    }
  }

  Future<CustomResponse> predict({required String query}) async {
    state = const AsyncValue.loading();
    updateState(const HomeState.loading());

    try {
      final response = await ref
          .read(homeApiProvider)
          .predictProduct(name: query);

      if (response.success && response.data != null) {
        final taskId = response.data['job_id'] as String;

        ref.read(appStateProvider.notifier).storeDeviceTask(taskId);
        await _storageService.saveLastTask(taskId, query);

        updateState(HomeState.taskCreated(taskId: taskId, query: query));
        _connectToWebSocket(taskId, query);

        return response;
      } else {
        updateState(HomeState.error(message: response.message));
        return response;
      }
    } catch (e) {
      updateState(HomeState.error(message: e.toString()));
      rethrow;
    }
  }

  void _connectToWebSocket(String taskId, String query) {
    logger.d('🔌 HomeProvider: Connecting to WebSocket for task: $taskId');
    _currentTaskId = taskId;
    final webSocketService = ref.read(websocketServiceProvider);

    _webSocketSubscription?.cancel();

    _webSocketSubscription = webSocketService
        .connect(taskId)
        .listen(
          (status) {
            logger.d('📊 HomeProvider received: status=${status.status}, progress=${status.progress}%, message=${status.message}');
            _handleWebSocketMessage(status, query);
          },
          onError: (error) {
            logger.e('❌ HomeProvider WebSocket error: $error');
            _checkAndReconnect(taskId, query);
          },
          onDone: () async {
            logger.d('🔚 HomeProvider WebSocket done');
            final currentState = state.value;
            if (currentState != null &&
                (currentState.isTaskCompleted || currentState.isTaskFailed)) {
              await _storageService.clearLastTask();
            } else {
              _checkAndReconnect(taskId, query);
            }
          },
        );

    logger.d('✅ HomeProvider: WebSocket subscription created');
  }

  Future<void> _checkAndReconnect(String taskId, String query) async {
    final currentState = state.value;
    if (currentState != null && (currentState.isTaskCompleted || currentState.isTaskFailed)) {
      logger.d('✅ Task already completed/failed, not reconnecting');
      return;
    }

    try {
      final response = await ref.read(homeApiProvider).checkTaskStatus(taskId);

      if (response.success && response.data?['exists'] == true) {
        final status = response.data?['status'];
        if (status == 'PROCESSING' || status == 'pending') {
          logger.d('🔄 Task still processing, reconnecting...');
          _attemptReconnection(taskId, query);
        } else if (status == 'SUCCESS' || status == 'completed') {
          final result = response.data?['result'];
          if (result != null) {
            logger.d('✅ Task completed, showing results');
            updateState(
              HomeState.taskCompleted(
                taskId: taskId,
                query: query,
                result: result,
              ),
            );
            await _storageService.clearLastTask();
            final webSocketService = ref.read(websocketServiceProvider);
            webSocketService.preventReconnect();
          }
        } else if (status == 'FAILED') {
          updateState(
            HomeState.taskFailed(
              taskId: taskId,
              query: query,
              error: response.data?['error'] ?? 'Task failed',
            ),
          );
          await _storageService.clearLastTask();
          final webSocketService = ref.read(websocketServiceProvider);
          webSocketService.preventReconnect();
        }
      } else {
        await _storageService.clearLastTask();
        updateState(const HomeState.initial());
      }
    } catch (e) {
      logger.e('Failed to check task status: $e');
    }
  }

  void _attemptReconnection(String taskId, String query) {
    Future.delayed(const Duration(seconds: 3), () async {
      final currentState = state.value;
      if (currentState != null &&
          !currentState.isTaskCompleted &&
          !currentState.isTaskFailed) {
        final response = await ref.read(homeApiProvider).checkTaskStatus(taskId);

        if (response.success && response.data?['exists'] == true) {
          final status = response.data?['status'];
          if (status == 'PROCESSING' || status == 'pending') {
            updateState(HomeState.reconnecting(taskId: taskId, query: query));
            _connectToWebSocket(taskId, query);
          } else if (status == 'SUCCESS' || status == 'completed') {
            final result = response.data?['result'];
            if (result != null) {
              updateState(
                HomeState.taskCompleted(
                  taskId: taskId,
                  query: query,
                  result: result,
                ),
              );
              await _storageService.clearLastTask();
            }
          } else if (status == 'FAILED') {
            updateState(
              HomeState.taskFailed(
                taskId: taskId,
                query: query,
                error: response.data?['error'] ?? 'Task failed',
              ),
            );
            await _storageService.clearLastTask();
          }
        } else {
          await _storageService.clearLastTask();
          updateState(const HomeState.initial());
        }
      }
    });
  }

  void _handleWebSocketMessage(TaskStatus status, String query) {
    logger.d(
      '📊 HomeProvider received: ${status.status}, Progress: ${status.progress}%, Message: ${status.message}',
    );

    final statusLower = status.status.toLowerCase();

    if (statusLower == 'completed' || status.progress >= 100) {
      updateState(
        HomeState.taskCompleted(
          taskId: status.taskId,
          query: query,
          result: status.result ?? [],
        ),
      );
      _storageService.clearLastTask();
      final webSocketService = ref.read(websocketServiceProvider);
      webSocketService.preventReconnect();
    } else if (statusLower == 'failed') {
      updateState(
        HomeState.taskFailed(
          taskId: status.taskId,
          query: query,
          error: status.message,
        ),
      );
      _storageService.clearLastTask();
      final webSocketService = ref.read(websocketServiceProvider);
      webSocketService.preventReconnect();
    } else if (status.progress > 0) {
      updateState(
        HomeState.taskProcessing(
          taskId: status.taskId,
          query: query,
          progress: status.progress,
          message: status.message,
        ),
      );
    }
  }

  void updateState(HomeState newState) {
    state = AsyncValue.data(newState);
  }

  Future<void> cancelTask() async {
    if (_currentTaskId != null) {
      _webSocketSubscription?.cancel();
      final webSocketService = ref.read(websocketServiceProvider);
      webSocketService.disconnect();
      await _storageService.clearLastTask();
      updateState(const HomeState.initial());
    }
  }

  void dispose() {
    _webSocketSubscription?.cancel();
  }
}