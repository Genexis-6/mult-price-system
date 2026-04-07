import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitaMain {
  static Future<SharedPreferences> initStorage() async {
    return await SharedPreferences.getInstance();
  }

  static void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    logger.d('Permission: ${settings.authorizationStatus}');
  }
}
