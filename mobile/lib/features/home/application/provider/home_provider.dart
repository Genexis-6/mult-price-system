import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/data/model/response_model.dart';
import 'package:mobile/features/home/application/provider/repo_provider.dart';
import 'package:mobile/features/home/application/state/home_state.dart';

class HomeProvider extends AsyncNotifier<HomeState> {
  @override
  FutureOr<HomeState> build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  Future<CustomResponse> predict({required String query}) async {
    return ref.read(homeApiProvider).predictProduct(name: query);
  }
}





final homeProvider = AsyncNotifierProvider<HomeProvider, HomeState>(HomeProvider.new);