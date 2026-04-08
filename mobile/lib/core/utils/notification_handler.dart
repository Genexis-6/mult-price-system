import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize for Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize for iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings: settings);
    
    logger.d("✅ Local notifications initialized");
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Create Android notification details with the app icon
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications for task updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher', // Use the app's launcher icon
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: payload,
      notificationDetails: details,
    );
    
    logger.d("✅ Local notification shown: $title");
  }

  static Future<void> showTaskCompletedNotification(String taskId) async {
    await showNotification(
      title: "Task Completed ✅",
      body: "Your results are ready!",
      payload: taskId,
    );
  }

  static Future<void> showTaskFailedNotification(String error) async {
    await showNotification(
      title: "Task Failed ❌",
      body: error,
    );
  }

  static Future<void> showProgressNotification(int progress, String message) async {
    await showNotification(
      title: "Task Progress",
      body: "$progress% - $message",
    );
  }
}