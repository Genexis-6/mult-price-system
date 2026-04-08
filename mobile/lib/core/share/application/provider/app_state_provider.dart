import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/core/share/application/state/app_state.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/core/utils/notification_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/model/device_model.dart';

final appStateProvider = AsyncNotifierProvider<AppStateProvider, AppState>(
  () => AppStateProvider(),
);

class AppStateProvider extends AsyncNotifier<AppState> {
  String? _currentFcmToken;

  @override
  FutureOr<AppState> build() async {
    logger.d("Initializing AppStateProvider...");

    // Set initial loading state
    state = const AsyncValue.data(AppState.loading());

    // Request notification permissions and get FCM token
    final token = await _requestPermissionsAndGetToken();

    if (token != null) {
      _currentFcmToken = token;
      // Register device with backend
      final device = await _registerDevice(token);
      if (device != null) {
        return AppState.registered(
          fcmToken: token,
          deviceId: device.deviceId,
          isNewDevice: device.isNew,
        );
      } else {
        return const AppState.error(message: "Failed to register device");
      }
    } else {
      return const AppState.error(message: "Failed to get FCM token");
    }
  }

  Future<String?> _requestPermissionsAndGetToken() async {
    try {
      logger.d("Requesting notification permissions...");

      // Check current permission status
      var permissionStatus = await Permission.notification.status;
      logger.d("Current notification permission status: $permissionStatus");

      if (!permissionStatus.isGranted) {
        // Request permission for Android 13+
        if (await Permission.notification.isDenied) {
          permissionStatus = await Permission.notification.request();
          logger.d("Permission requested, new status: $permissionStatus");
        }
      }

      if (permissionStatus.isGranted) {
        logger.d("✅ Notification permission granted");

        // Get FCM token (works for both Android and iOS)
        String? token = await FirebaseMessaging.instance.getToken();
        logger.d("✅ FCM Token obtained: ${token?.substring(0, 20)}...");

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          logger.d("🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...");
          _handleTokenRefresh(newToken);
        });

        // Inside _requestPermissionsAndGetToken method, update the onMessage listener:
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          logger.d(
            "📱 Received foreground message: ${message.notification?.title}",
          );

          // Show local notification for foreground messages
          if (message.notification != null) {
            NotificationService.showNotification(
              title: message.notification!.title ?? "Notification",
              body: message.notification!.body ?? "",
              payload: message.data['task_id'],
            );
          }

          // Handle data messages
          if (message.data.isNotEmpty) {
            logger.d("Message data: ${message.data}");
            final taskId = message.data['task_id'];
            final status = message.data['status'];

            if (status == 'completed') {
              NotificationService.showTaskCompletedNotification(taskId ?? "");
            } else if (status == 'failed') {
              NotificationService.showTaskFailedNotification(
                message.data['error'] ?? "Task failed",
              );
            }
          }
        });

        // Also handle when app is in background and opened via notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          logger.d("📱 App opened from notification");
          // Navigate to appropriate screen
          final taskId = message.data['task_id'];
          if (taskId != null) {
            // Navigate to results screen for this task
            // You can use a navigation service here
          }
        });

        // Handle initial message when app is opened from a terminated state
        RemoteMessage? initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) {
          logger.d("📱 App opened from terminated state with notification");
          final taskId = initialMessage.data['task_id'];
          // Navigate to results screen
        }

        return token;
      } else if (permissionStatus.isPermanentlyDenied) {
        logger.w("⚠️ Notification permission permanently denied");
        // Open app settings
        await openAppSettings();
        return null;
      } else {
        logger.w("⚠️ Notification permission denied");
        return null;
      }
    } catch (e) {
      logger.e("❌ Error getting FCM token: $e");
      return null;
    }
  }

  Future<Device?> _registerDevice(String fcmToken) async {
    try {
      logger.d("📡 Registering device with backend...");
      final response = await ref
          .read(appStateApiProvider)
          .storeDeviceFcm(fcmToken: fcmToken);

      logger.d("Response data: ${response.data}");

      if (response.success && response.data != null) {
        // Ensure we're parsing the correct structure
        final deviceData = response.data as Map<String, dynamic>;
        logger.d("Device data: $deviceData");

        final device = Device.fromJson(deviceData);
        logger.d("✅ Device registered successfully: ID=${device.deviceId}");
        return device;
      } else {
        logger.e("❌ Failed to register device: ${response.message}");
        return null;
      }
    } catch (e, stackTrace) {
      logger.e("❌ Error registering device: $e");
      logger.e("StackTrace: $stackTrace");
      return null;
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    logger.d("🔄 Handling token refresh: ${newToken.substring(0, 20)}...");

    final currentState = state.value;
    // Use the extension to check if registered
    if (currentState != null && currentState.isRegistered) {
      // Set refreshing state
      state = AsyncValue.data(
        AppState.tokenRefreshing(
          oldToken: currentState.fcmToken ?? "",
          newToken: newToken,
        ),
      );

      // Update token on backend
      final device = await _registerDevice(newToken);

      if (device != null) {
        _currentFcmToken = newToken;
        state = AsyncValue.data(
          AppState.registered(
            fcmToken: newToken,
            deviceId: device.deviceId,
            isNewDevice: false,
          ),
        );
        logger.d("✅ Token refreshed successfully");
      } else {
        // Revert to previous state
        state = AsyncValue.data(currentState);
        logger.e("❌ Failed to refresh token");
      }
    }
  }

  Future<void> storeDeviceTask(String taskId) async {
    final currentState = state.value;
    // Use the extension to check if registered
    if (currentState != null && currentState.isRegistered) {
      try {
        logger.d("📝 Storing task $taskId for device");
        final response = await ref
            .read(appStateApiProvider)
            .storeDeviceTask(fcmToken: currentState.fcmToken!, taskId: taskId);

        if (response.success) {
          logger.d("✅ Task stored successfully");
        } else {
          logger.e("❌ Failed to store task: ${response.message}");
        }
      } catch (e) {
        logger.e("❌ Error storing task: $e");
      }
    }
  }

  Future<bool> deleteDeviceTask(String taskId) async {
    final currentState = state.value;
    if (currentState != null && currentState.isRegistered) {
      try {
        logger.d("🗑️ Deleting task $taskId");
        final response = await ref
            .read(appStateApiProvider)
            .deleteDeviceTask(taskId);

        if (response.success) {
          logger.d("✅ Task deleted successfully");
          return true;
        }
      } catch (e) {
        logger.e("❌ Error deleting task: $e");
      }
    }
    return false;
  }

  Future<void> refreshDeviceToken() async {
    logger.d("🔄 Manually refreshing device token...");
    final newToken = await FirebaseMessaging.instance.getToken();
    if (newToken != null && newToken != _currentFcmToken) {
      await _handleTokenRefresh(newToken);
    }
  }

  void resetState() {
    logger.d("🔄 Resetting app state");
    state = const AsyncValue.data(AppState.loading());
    _currentFcmToken = null;
    // Reinitialize
    build();
  }
}
