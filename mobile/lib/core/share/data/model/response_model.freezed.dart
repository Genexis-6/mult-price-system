// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomResponse _$CustomResponseFromJson(Map<String, dynamic> json) {
  return _CustomResponse.fromJson(json);
}

/// @nodoc
mixin _$CustomResponse {
  @JsonKey(name: "status_code")
  int get statusCode => throw _privateConstructorUsedError;
  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: "data")
  dynamic get data => throw _privateConstructorUsedError;
  @JsonKey(name: "success")
  bool get success => throw _privateConstructorUsedError;
  @JsonKey(name: "error_code")
  String? get errorCode => throw _privateConstructorUsedError;

  /// Serializes this CustomResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomResponseCopyWith<CustomResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomResponseCopyWith<$Res> {
  factory $CustomResponseCopyWith(
    CustomResponse value,
    $Res Function(CustomResponse) then,
  ) = _$CustomResponseCopyWithImpl<$Res, CustomResponse>;
  @useResult
  $Res call({
    @JsonKey(name: "status_code") int statusCode,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") dynamic data,
    @JsonKey(name: "success") bool success,
    @JsonKey(name: "error_code") String? errorCode,
  });
}

/// @nodoc
class _$CustomResponseCopyWithImpl<$Res, $Val extends CustomResponse>
    implements $CustomResponseCopyWith<$Res> {
  _$CustomResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? message = null,
    Object? data = freezed,
    Object? success = null,
    Object? errorCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            statusCode: null == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as dynamic,
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorCode: freezed == errorCode
                ? _value.errorCode
                : errorCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomResponseImplCopyWith<$Res>
    implements $CustomResponseCopyWith<$Res> {
  factory _$$CustomResponseImplCopyWith(
    _$CustomResponseImpl value,
    $Res Function(_$CustomResponseImpl) then,
  ) = __$$CustomResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "status_code") int statusCode,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") dynamic data,
    @JsonKey(name: "success") bool success,
    @JsonKey(name: "error_code") String? errorCode,
  });
}

/// @nodoc
class __$$CustomResponseImplCopyWithImpl<$Res>
    extends _$CustomResponseCopyWithImpl<$Res, _$CustomResponseImpl>
    implements _$$CustomResponseImplCopyWith<$Res> {
  __$$CustomResponseImplCopyWithImpl(
    _$CustomResponseImpl _value,
    $Res Function(_$CustomResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? message = null,
    Object? data = freezed,
    Object? success = null,
    Object? errorCode = freezed,
  }) {
    return _then(
      _$CustomResponseImpl(
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as dynamic,
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorCode: freezed == errorCode
            ? _value.errorCode
            : errorCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomResponseImpl implements _CustomResponse {
  const _$CustomResponseImpl({
    @JsonKey(name: "status_code") this.statusCode = 200,
    @JsonKey(name: "message") this.message = '',
    @JsonKey(name: "data") this.data,
    @JsonKey(name: "success") this.success = false,
    @JsonKey(name: "error_code") this.errorCode,
  });

  factory _$CustomResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomResponseImplFromJson(json);

  @override
  @JsonKey(name: "status_code")
  final int statusCode;
  @override
  @JsonKey(name: "message")
  final String message;
  @override
  @JsonKey(name: "data")
  final dynamic data;
  @override
  @JsonKey(name: "success")
  final bool success;
  @override
  @JsonKey(name: "error_code")
  final String? errorCode;

  @override
  String toString() {
    return 'CustomResponse(statusCode: $statusCode, message: $message, data: $data, success: $success, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomResponseImpl &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    statusCode,
    message,
    const DeepCollectionEquality().hash(data),
    success,
    errorCode,
  );

  /// Create a copy of CustomResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomResponseImplCopyWith<_$CustomResponseImpl> get copyWith =>
      __$$CustomResponseImplCopyWithImpl<_$CustomResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomResponseImplToJson(this);
  }
}

abstract class _CustomResponse implements CustomResponse {
  const factory _CustomResponse({
    @JsonKey(name: "status_code") final int statusCode,
    @JsonKey(name: "message") final String message,
    @JsonKey(name: "data") final dynamic data,
    @JsonKey(name: "success") final bool success,
    @JsonKey(name: "error_code") final String? errorCode,
  }) = _$CustomResponseImpl;

  factory _CustomResponse.fromJson(Map<String, dynamic> json) =
      _$CustomResponseImpl.fromJson;

  @override
  @JsonKey(name: "status_code")
  int get statusCode;
  @override
  @JsonKey(name: "message")
  String get message;
  @override
  @JsonKey(name: "data")
  dynamic get data;
  @override
  @JsonKey(name: "success")
  bool get success;
  @override
  @JsonKey(name: "error_code")
  String? get errorCode;

  /// Create a copy of CustomResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomResponseImplCopyWith<_$CustomResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
