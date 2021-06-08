// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_hsl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColorHSL _$ColorHSLFromJson(Map<String, dynamic> json) {
  return ColorHSL(
    (json['h'] as num).toDouble(),
    (json['s'] as num).toDouble(),
    (json['l'] as num).toDouble(),
    (json['ratio'] as num).toDouble(),
  );
}

Map<String, dynamic> _$ColorHSLToJson(ColorHSL instance) => <String, dynamic>{
      'h': instance.h,
      's': instance.s,
      'l': instance.l,
      'ratio': instance.ratio,
    };
