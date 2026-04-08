import 'package:dio/dio.dart';
import 'package:mobile/core/share/data/model/response_model.dart';
import 'package:mobile/core/utils/api_exception_handler.dart';

class AppStateApi {
  final Dio _api;

  AppStateApi(this._api);

  Future<CustomResponse> storeDeviceFcm({required String fcmToken}) async {
    try {
      final res = await _api.post("/device/create", data: {
        "fcm_token": fcmToken,
      });
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

  Future<CustomResponse> storeDeviceTask({
    required String fcmToken,
    required String taskId,
  }) async {
    try {
      final res = await _api.post("/device/device-task", data: {
        "fcm_token": fcmToken,
        "task_id": taskId,
      });
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

  
  Future<CustomResponse> deleteDeviceTask(String taskId) async {
    try {
      final res = await _api.delete("/device/task/$taskId");
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
}