// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomResponseImpl _$$CustomResponseImplFromJson(Map<String, dynamic> json) =>
    _$CustomResponseImpl(
      statusCode: (json['status_code'] as num?)?.toInt() ?? 200,
      message: json['message'] as String? ?? '',
      data: json['data'],
      success: json['success'] as bool? ?? false,
      errorCode: json['error_code'] as String?,
    );

Map<String, dynamic> _$$CustomResponseImplToJson(
  _$CustomResponseImpl instance,
) => <String, dynamic>{
  'status_code': instance.statusCode,
  'message': instance.message,
  'data': instance.data,
  'success': instance.success,
  'error_code': instance.errorCode,
};
