import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/share/application/provider/repo_provider.dart';
import 'package:mobile/inita_main.dart';
import 'package:mobile/mula_search.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();

  // Configure Google Fonts to use HTTP instead of local files
  GoogleFonts.config.allowRuntimeFetching = true;
  final pref = await InitaMain.initStorage();
  runApp(
    ProviderScope(
      overrides: [sharedPreferenceProvider.overrideWithValue(pref)],
      child: MulaSearch(),
    ),
  );
}
