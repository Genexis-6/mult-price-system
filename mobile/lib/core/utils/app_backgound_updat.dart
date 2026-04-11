import 'package:mobile/core/share/data/model/notification_payload.dart';
import 'package:mobile/core/share/data/repo/storage_service.dart';
import 'package:mobile/features/home/data/api/home_api.dart';
import 'package:mobile/core/share/data/api/app_state_api.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

class AppBackgroundUpdate {
  final HomeApi _homeApi;
  final AppStateApi _appStateApi;
  final StorageService _storageService;
  final String? fcmToken;

  AppBackgroundUpdate({
    required StorageService storageService,
    required HomeApi homeApi,
    required AppStateApi appStateApi,
    this.fcmToken,
  })  : _homeApi = homeApi,
        _appStateApi = appStateApi,
        _storageService = storageService;

  Future<Map<String, String?>?> get taskInfo => _storageService.getLastTask();

  Future<bool> checkTaskRunning() async {
    final taskInfo = await _storageService.getLastTask();
    if (taskInfo == null) {
      return false;
    }
    
    if (taskInfo.containsKey("taskId")) {
      final response = await _homeApi.checkTaskStatus(taskInfo["taskId"]!);
      
      if (response.success && response.data != null) {
        final status = response.data['status'];
        
        switch (status) {
          case "pending":
          case "processing":
            logger.d("Task ${taskInfo["taskId"]} is still running with status: $status");
            return true;
          case "completed":
            logger.d("Task ${taskInfo["taskId"]} is completed");
            await _storageService.clearLastTask();
            
            // Send local notification about completion
            if (fcmToken != null) {
              await sendLocalNotification(
                title: "Task Completed ✅",
                body: "Your task has been completed successfully!",
                data: {"task_id": taskInfo["taskId"]!},
              );
            }
            return false;
          case "failed":
            logger.d("Task ${taskInfo["taskId"]} failed");
            await _storageService.clearLastTask();
            return false;
          default:
            return false;
        }
      }
    }
    return false;
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (fcmToken == null) {
      logger.w("Cannot send notification: No FCM token available");
      return;
    }

    try {
      final payload = NotificationPayload(
        title: title,
        body: body,
        fcmToken: fcmToken!,
        data: data ?? {},
      );
      
      final response = await _appStateApi.sendNotification(payload);
      
      if (response.success) {
        logger.d("✅ Local notification sent successfully");
      } else {
        logger.e("❌ Failed to send local notification: ${response.message}");
      }
    } catch (e) {
      logger.e("❌ Error sending notification: $e");
    }
  }

  Future<void> sendTaskProgressNotification(String taskId, int progress, String message) async {
    await sendLocalNotification(
      title: "Task Progress: $progress%",
      body: message,
      data: {
        "task_id": taskId,
        "progress": progress,
        "type": "task_progress",
      },
    );
  }

  Future<void> sendTaskCompletedNotification(String taskId, String resultSummary) async {
    await sendLocalNotification(
      title: "✅ Task Completed!",
      body: resultSummary,
      data: {
        "task_id": taskId,
        "type": "task_completed",
      },
    );
  }

  Future<void> sendTaskFailedNotification(String taskId, String error) async {
    await sendLocalNotification(
      title: "❌ Task Failed",
      body: error.length > 100 ? "${error.substring(0, 100)}..." : error,
      data: {
        "task_id": taskId,
        "type": "task_failed",
        "error": error,
      },
    );
  }
}