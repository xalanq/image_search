import 'package:json_annotation/json_annotation.dart';

part 'color_hsl.g.dart';

@JsonSerializable()
class ColorHSL {
  final double h;
  final double s;
  final double l;
  final double ratio;

  ColorHSL(this.h, this.s, this.l, this.ratio);

  factory ColorHSL.fromJson(Map<String, dynamic> json) => _$ColorHSLFromJson(json);
  Map<String, dynamic> toJson() => _$ColorHSLToJson(this);
}
