// lib/core/json_converters/icon_data_converter.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class IconDataConverter implements JsonConverter<IconData, Map<String, dynamic>> {
  const IconDataConverter();

  @override
  IconData fromJson(Map<String, dynamic> json) {
    return IconData(
      json['codePoint'] as int,
      fontFamily: json['fontFamily'] as String?,
      fontPackage: json['fontPackage'] as String?,
      matchTextDirection: json['matchTextDirection'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson(IconData object) {
    return {
      'codePoint': object.codePoint,
      'fontFamily': object.fontFamily,
      'fontPackage': object.fontPackage,
      'matchTextDirection': object.matchTextDirection,
    };
  }
}