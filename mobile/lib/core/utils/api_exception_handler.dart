import 'package:dio/dio.dart';
import 'package:mobile/core/share/data/model/response_model.dart';

class ApiExceptionHandler {
  static CustomResponse handleDioException(DioException e) {
    String message = 'An unexpected error occurred';
    int statusCode = 500;
    String? errorCode;
    dynamic data;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        errorCode = 'CONNECTION_TIMEOUT';
        statusCode = 408;
        break;
        
      case DioExceptionType.sendTimeout:
        message = 'Send timeout. Please try again.';
        errorCode = 'SEND_TIMEOUT';
        statusCode = 408;
        break;
        
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout. Please try again.';
        errorCode = 'RECEIVE_TIMEOUT';
        statusCode = 408;
        break;
        
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        errorCode = 'REQUEST_CANCELLED';
        statusCode = 499;
        break;
        
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network settings.';
        errorCode = 'NO_INTERNET';
        statusCode = 503;
        break;
        
      case DioExceptionType.badResponse:
        statusCode = e.response?.statusCode ?? 500;
        data = e.response?.data;
        
        switch (statusCode) {
          case 400:
            message = _parseErrorMessage(data) ?? 'Bad request. Please check your input.';
            errorCode = 'BAD_REQUEST';
            break;
          case 401:
            message = 'Unauthorized. Please login again.';
            errorCode = 'UNAUTHORIZED';
            break;
          case 403:
            message = 'Access forbidden. You don\'t have permission.';
            errorCode = 'FORBIDDEN';
            break;
          case 404:
            message = 'Resource not found.';
            errorCode = 'NOT_FOUND';
            break;
          case 409:
            message = 'Conflict with current state.';
            errorCode = 'CONFLICT';
            break;
          case 422:
            message = _parseValidationErrors(data) ?? 'Validation failed.';
            errorCode = 'VALIDATION_ERROR';
            break;
          case 429:
            message = 'Too many requests. Please try again later.';
            errorCode = 'TOO_MANY_REQUESTS';
            break;
          case 500:
            message = 'Internal server error. Please try again later.';
            errorCode = 'SERVER_ERROR';
            break;
          case 502:
            message = 'Bad gateway. Please try again later.';
            errorCode = 'BAD_GATEWAY';
            break;
          case 503:
            message = 'Service unavailable. Please try again later.';
            errorCode = 'SERVICE_UNAVAILABLE';
            break;
          default:
            message = _parseErrorMessage(data) ?? 'Something went wrong. Please try again.';
            errorCode = 'UNKNOWN_ERROR';
        }
        break;
        
      case DioExceptionType.badCertificate:
        message = 'Invalid security certificate.';
        errorCode = 'BAD_CERTIFICATE';
        statusCode = 495;
        break;
        
      case DioExceptionType.unknown:
        if (e.error != null && e.error.toString().contains('SocketException')) {
          message = 'No internet connection. Please check your network.';
          errorCode = 'NO_INTERNET';
          statusCode = 503;
        } else {
          message = 'An unexpected error occurred: ${e.message}';
          errorCode = 'UNKNOWN_ERROR';
          statusCode = 500;
        }
        break;
    }

    return CustomResponse.error(
      message: message,
     
      statusCode: statusCode,
      data: data,
    );
  }

  static String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    
    // Try different common response formats
    if (data is Map<String, dynamic>) {
      // Format: {"message": "Error message"}
      if (data.containsKey('message')) return data['message'].toString();
      
      // Format: {"error": "Error message"}
      if (data.containsKey('error')) return data['error'].toString();
      
      // Format: {"errors": {"field": ["error message"]}}
      if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is Map) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
      }
      
      // Format: {"detail": "Error message"}
      if (data.containsKey('detail')) return data['detail'].toString();
      
      // Format: {"status_message": "Error message"}
      if (data.containsKey('status_message')) return data['status_message'].toString();
    }
    
    // If data is a string
    if (data is String) return data;
    
    return null;
  }

  static String? _parseValidationErrors(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand((e) => e is List ? e.map((m) => m.toString()) : [e.toString()])
            .join('\n');
        return messages;
      }
    }
    
    return _parseErrorMessage(data);
  }
}