// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageResult _$ImageResultFromJson(Map<String, dynamic> json) {
  return ImageResult(
    json['path'] as String,
    json['url'] as String,
    json['landing_url'] as String,
    (json['labels'] as List<dynamic>).map((e) => e as String).toList(),
    json['title'] as String,
    json['size'] as int,
    json['width'] as int,
    json['height'] as int,
    (json['colors'] as List<dynamic>).map((e) => ColorHSL.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

Map<String, dynamic> _$ImageResultToJson(ImageResult instance) => <String, dynamic>{
      'path': instance.path,
      'url': instance.url,
      'landing_url': instance.landingURL,
      'labels': instance.labels,
      'title': instance.title,
      'size': instance.size,
      'width': instance.width,
      'height': instance.height,
      'colors': instance.colors,
    };
