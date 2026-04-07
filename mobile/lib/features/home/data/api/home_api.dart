import 'package:dio/dio.dart';
import 'package:mobile/core/share/data/model/response_model.dart';

import '../../../../core/utils/api_exception_handler.dart';

class HomeApi {
  final Dio _api;

  HomeApi(this._api);
  Future<CustomResponse> predictProduct({required String name}) async {
    try {
      final res = await _api.post("/predict/", data: {"query": name});
      return CustomResponse.fromJson(res.data);
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'An unexpected error occurred: ${e.toString()}',
        errorCode: 'UNEXPECTED_ERROR',
        statusCode: 500,
      );
    }
  }

   Future<CustomResponse> checkTaskStatus(String taskId) async {
    try {
      final res = await _api.get("/predict/status/$taskId");
      return CustomResponse.fromJson(res.data);
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to check task status',
        errorCode: 'STATUS_CHECK_ERROR',
        statusCode: 500,
      );
    }
  }

  // Gen
}
