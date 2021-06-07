import 'package:image_search/model/color_hsl.dart';

class ImageResult {
  String path;
  String url;
  String landingURL;
  List<String> labels;
  String title;
  int size;
  int width;
  int height;
  List<ColorHSL> colors;

  ImageResult({
    required this.path,
    required this.url,
    required this.landingURL,
    required this.labels,
    required this.title,
    required this.size,
    required this.width,
    required this.height,
    required this.colors,
  });
}
