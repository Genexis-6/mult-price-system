import 'package:dio/dio.dart';
import 'package:mobile/core/share/data/model/response_model.dart';
import 'package:mobile/core/utils/api_exception_handler.dart';
import 'package:mobile/core/utils/logger_utlis.dart';
// import 'package:mobile/features/track/data/model/price_alert_model.dart';
import 'package:mobile/features/track/data/model/price_tracking_res_model.dart';

class PriceTrackingApi {
  final Dio _api;

  PriceTrackingApi(this._api);

  /// Create a new price alert
  /// POST /price-tracking/alert
  Future<CustomResponse> createPriceAlert({
    required String email,
    required String productName,
    required double targetPrice,
  }) async {
    try {
      final schema = CreatePriceAlertModel(
        email: email,
        productName: productName,
        targetPrice: targetPrice,
      );
      
      final res = await _api.post(
        "/price-tracking/alert",
        data: schema.toJson(),
      );
      
      logger.d("Create alert response: ${res.data}");
      
      return CustomResponse.success(
        data: CreateAlertApiResponse.fromJson(res.data),
        message: 'Alert created successfully',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to create price alert: ${e.toString()}',
        errorCode: 'CREATE_ALERT_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Get all alerts for a user
  /// GET /price-tracking/alerts/{email}
  Future<CustomResponse> getUserAlerts(String email) async {
    try {
      final res = await _api.get("/price-tracking/alerts/$email");
      logger.d("Get user alerts response: ${res.data}");
      
      return CustomResponse.success(
        data: GetUserAlertsApiResponse.fromJson(res.data),
        message: 'Alerts retrieved successfully',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to get user alerts: ${e.toString()}',
        errorCode: 'GET_ALERTS_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Cancel a price alert
  /// DELETE /price-tracking/alert/{alert_id}
  Future<CustomResponse> cancelAlert(int alertId) async {
    try {
      final res = await _api.delete("/price-tracking/alert/$alertId");
      logger.d("Cancel alert response: ${res.data}");
      
      return CustomResponse.success(
        data: CancelAlertApiResponse.fromJson(res.data),
        message: 'Alert cancelled successfully',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return CustomResponse.error(
          message: 'Alert not found',
          errorCode: 'ALERT_NOT_FOUND',
          statusCode: 404,
        );
      }
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to cancel alert: ${e.toString()}',
        errorCode: 'CANCEL_ALERT_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Update a price alert
  /// PATCH /price-tracking/alert/{alert_id}
  Future<CustomResponse> updateAlert({
    required int alertId,
    double? targetPrice,
    AlertStatus? status,
  }) async {
    try {
      final schema = UpdatePriceAlertModel(
        targetPrice: targetPrice,
        status: status,
      );
      
      final res = await _api.patch(
        "/price-tracking/alert/$alertId",
        data: schema.toJson(),
      );
      
      logger.d("Update alert response: ${res.data}");
      
      return CustomResponse.success(
        data: PriceAlertResponse.fromJson(res.data['data']),
        message: 'Alert updated successfully',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to update alert: ${e.toString()}',
        errorCode: 'UPDATE_ALERT_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Manually trigger price check for all alerts
  /// POST /price-tracking/check-alerts
  Future<CustomResponse> triggerCheckAllAlerts() async {
    try {
      final res = await _api.post("/price-tracking/check-alerts");
      logger.d("Trigger check all alerts response: ${res.data}");
      
      return CustomResponse.success(
        data: TriggerCheckApiResponse.fromJson(res.data),
        message: 'Price check triggered',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to trigger price check: ${e.toString()}',
        errorCode: 'TRIGGER_CHECK_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Manually check a single price alert
  /// POST /price-tracking/check-alert/{alert_id}
  Future<CustomResponse> triggerCheckSingleAlert(int alertId) async {
    try {
      final res = await _api.post("/price-tracking/check-alert/$alertId");
      logger.d("Trigger single alert check response: ${res.data}");
      
      return CustomResponse.success(
        data: TriggerCheckApiResponse.fromJson(res.data),
        message: 'Single alert check triggered',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to trigger single alert check: ${e.toString()}',
        errorCode: 'TRIGGER_SINGLE_CHECK_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Get price comparison for a product
  /// GET /price-tracking/compare/{product_name}
  Future<CustomResponse> getPriceComparison(String productName) async {
    try {
      final res = await _api.get("/price-tracking/compare/$productName");
      logger.d("Price comparison response: ${res.data}");
      
      return CustomResponse.success(
        data: PriceComparisonResponse.fromJson(res.data['data']),
        message: 'Price comparison retrieved',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to get price comparison: ${e.toString()}',
        errorCode: 'COMPARISON_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Get price history for an alert
  /// GET /price-tracking/history/{alert_id}
  Future<CustomResponse> getPriceHistory(int alertId) async {
    try {
      final res = await _api.get("/price-tracking/history/$alertId");
      logger.d("Price history response: ${res.data}");
      
      final history = (res.data['data'] as List)
          .map((item) => PriceHistoryResponse.fromJson(item))
          .toList();
      
      return CustomResponse.success(
        data: history,
        message: 'Price history retrieved',
      );
    } on DioException catch (e) {
      return ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      return CustomResponse.error(
        message: 'Failed to get price history: ${e.toString()}',
        errorCode: 'HISTORY_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Check task status
  /// GET /predict/status/{task_id}
  Future<CustomResponse> checkTaskStatus(String taskId) async {
    try {
      final res = await _api.get("/predict/status/$taskId");
      logger.d("Task status response: ${res.data}");
      
      return CustomResponse.success(
        data: res.data['data'] as Map<String, dynamic>,
        message: res.data['message'] ?? 'Task status retrieved',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
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
}