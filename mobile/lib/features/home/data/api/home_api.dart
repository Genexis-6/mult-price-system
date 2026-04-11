import 'package:dio/dio.dart';
import 'package:mobile/core/share/data/model/response_model.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

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
      logger.d("Task status response: ${res.data}");
      return CustomResponse.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Task not found - treat as not existing
        return CustomResponse.success(
          data: {"exists": false, "status": "NOT_FOUND"},
          message: "Task not found",
        );
      }
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to check task status: ${e.toString()}',
        errorCode: 'STATUS_CHECK_ERROR',
        statusCode: 500,
      );
    }
  }

  // Gen
}
