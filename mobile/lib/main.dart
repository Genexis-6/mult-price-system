import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/inita_main.dart';
import 'package:mobile/mula_search.dart';
import 'package:workmanager/workmanager.dart';



@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Check for pending tasks
    // You can make API calls here
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
   await dotenv.load();

    // Initialize WorkManager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    "task-status-check",
    "taskStatusCheck",
    frequency: Duration(minutes: 15),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // Initialize storage
  final pref = await InitaMain.initStorage();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferenceProvider.overrideWithValue(pref),
      ],
      child: const MulaSearch(),
    ),
  );
}