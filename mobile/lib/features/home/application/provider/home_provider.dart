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

  @override
  FutureOr<HomeState> build() async {
    _storageService = ref.read(storageServiceProvider);

    // Check for existing task when app starts
    final lastTask = await _storageService.getLastTask();
    logger.d(lastTask);

    if (lastTask != null) {
      final taskId = lastTask['taskId']!;
      final query = lastTask['query']!;

      // Check if task still exists on backend
      final response = await ref.read(homeApiProvider).checkTaskStatus(taskId);

      if (response.success && response.data?['exists'] == true) {
        // Reconnect to existing task
        state = AsyncValue.data(
          HomeState.reconnecting(taskId: taskId, query: query),
        );
        _connectToWebSocket(taskId, query);
        return HomeState.reconnecting(taskId: taskId, query: query);
      } else {
        await _storageService.clearLastTask();
        return const HomeState.initial();
      }
    }

    return const HomeState.initial();
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

        // Update to taskCreated state - this will show the skeleton
        updateState(HomeState.taskCreated(taskId: taskId, query: query));

        // Connect to WebSocket - this will update to processing when messages arrive
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

    // Add a small delay to ensure WebSocket is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _webSocketSubscription = webSocketService
          .connect(taskId)
          .listen(
            (status) {
              logger.d(
                '📊 HomeProvider received: ${status.status}, Progress: ${status.progress}%',
              );
              _handleWebSocketMessage(status, query);
            },
            onError: (error) {
              logger.d('❌ HomeProvider WebSocket error: $error');
              updateState(HomeState.error(message: 'WebSocket error: $error'));
            },
            onDone: () async {
              logger.d('🔚 HomeProvider WebSocket done');
              final currentState = state.value;
              if (currentState != null &&
                  (currentState.isTaskCompleted || currentState.isTaskFailed)) {
                await _storageService.clearLastTask();
              }
            },
          );
    });

    logger.d('✅ HomeProvider: WebSocket subscription created');
  }

  void _handleWebSocketMessage(TaskStatus status, String query) {
    logger.d(
      '📊 HomeProvider received: ${status.status}, Progress: ${status.progress}%, Message: ${status.message}',
    );

    final statusLower = status.status.toLowerCase();

    if (statusLower == 'completed' || status.progress >= 100) {
      // Task completed successfully
      updateState(
        HomeState.taskCompleted(
          taskId: status.taskId,
          query: query,
          result: status.result ?? [],
        ),
      );
      // _storageService.clearLastTask();
    } else if (statusLower == 'failed') {
      // Task failed
      updateState(
        HomeState.taskFailed(
          taskId: status.taskId,
          query: query,
          error: status.message,
        ),
      );
      _storageService.clearLastTask();
    } else if (status.progress > 0) {
      // Progress update
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
