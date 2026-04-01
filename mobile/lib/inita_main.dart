import 'package:shared_preferences/shared_preferences.dart';

class InitaMain {
  static Future<SharedPreferences> initStorage() async {
    return await SharedPreferences.getInstance();
  }
}
