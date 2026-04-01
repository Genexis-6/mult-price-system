import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repo/repo.dart';
import '../../domain/repo.dart';

final sharedPreferenceProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final appStorageProvider = Provider<StorageRepo>(
  (ref) => StorageRepoImpl(ref.read(sharedPreferenceProvider)),
);
