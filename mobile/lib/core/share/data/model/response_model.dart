import 'package:freezed_annotation/freezed_annotation.dart';

part 'response_model.freezed.dart';
part 'response_model.g.dart';

@freezed
class CustomResponse with _$CustomResponse {
  const factory CustomResponse({
    @JsonKey(name: "status_code") @Default(200) int statusCode,
    @JsonKey(name: "message") @Default('') String message,
    @JsonKey(name: "data") dynamic data,
    @JsonKey(name: "success") @Default(false) bool success,
    @JsonKey(name: "error_code") String? errorCode,
  }) = _CustomResponse;

  factory CustomResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomResponseFromJson(json);
  
  factory CustomResponse.success({
    required dynamic data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    return CustomResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }
  
  factory CustomResponse.error({
    required String message,
    String? errorCode,
    int statusCode = 400,
    dynamic data,
  }) {
    return CustomResponse(
      success: false,
      message: message,
      errorCode: errorCode,
      statusCode: statusCode,
      data: data,
    );
  }
}