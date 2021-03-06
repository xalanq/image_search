import 'package:image_search/consts.dart';
import 'package:image_search/model/color_hsl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'image_result.g.dart';

@JsonSerializable()
class ImageResult {
  String get imageURL => p.join(Consts.imageHost, path);

  final String path;
  final String url;
  @JsonKey(name: 'landing_url')
  final String landingURL;
  final List<String> labels;
  final String title;
  final int size;
  final int width;
  final int height;
  final List<ColorHSL> colors;

  ImageResult(
    this.path,
    this.url,
    this.landingURL,
    this.labels,
    this.title,
    this.size,
    this.width,
    this.height,
    this.colors,
  );

  factory ImageResult.fromJson(Map<String, dynamic> json) => _$ImageResultFromJson(json);
  Map<String, dynamic> toJson() => _$ImageResultToJson(this);
}
