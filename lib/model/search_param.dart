

String rangeQuery<T extends num>(String name, T? min, T? max) {
  if (max == null)
    return '{"range": {"$name": {"gte": $min}}}';
  if (min == null)
    return '{"range": {"$name": {"lte": $max}}}';
  if (min <= max)
    return '{"range": {"$name": {"gte": $min, "lte": $max}}}';
  return '{"bool": {"should": [{"range": {"$name": {"lte": $max}}}, {"range": {"$name": {"gte": $min}}}]}}';
}

class SizeParam {
  final int? widthMin;
  final int? widthMax;
  final int? heightMin;
  final int? heightMax;

  const SizeParam(this.widthMin, this.widthMax, this.heightMin, this.heightMax);

  const SizeParam.exact(int width, int height)
      : widthMin = width,
        widthMax = width,
        heightMin = height,
        heightMax = height;


  List<String> queries() {
    List<String> queries = [];
    if (widthMin != null || widthMax != null) queries.add(rangeQuery("width", widthMin, widthMax));
    if (heightMin != null || heightMax != null) queries.add(rangeQuery("height", heightMin, heightMax));
    return queries;
  }
}

const SizeAny = SizeParam(null, null, null, null);
const SizeSmall = SizeParam(null, 300, null, 300);
const SizeMedium = SizeParam(300, 1000, 300, 1000);
const SizeLarge = SizeParam(1000, 3000, 1000, 3000);
const SizeSuperLarge = SizeParam(3000, null, 3000, null);
const Size800x600 = SizeParam.exact(800, 600);
const Size1024x768 = SizeParam.exact(1024, 768);
const Size1280x760 = SizeParam.exact(1280, 720);
const Size1366x768 = SizeParam.exact(1366, 768);
const Size1440x1080 = SizeParam.exact(1440, 1080);
const Size1920x1080 = SizeParam.exact(1920, 1080);
const Size1920x1440 = SizeParam.exact(1920, 1440);

class ColorParam {
  static const hDelta = 10.0;
  static const sDelta = 0.1;
  static const lDelta = 0.1;
  static const gRatioMin = 0.3;
  static const gRatioMax = 1.0;

  final double? hMin;
  final double? hMax;
  final double? sMin;
  final double? sMax;
  final double? lMin;
  final double? lMax;
  final double? ratioMin;
  final double? ratioMax;

  const ColorParam(
    this.hMin,
    this.hMax,
    this.sMin,
    this.sMax,
    this.lMin,
    this.lMax,
    this.ratioMin,
    this.ratioMax,
  );

  const ColorParam.color(double? h, double? s, double? l)
      : hMin = h == null ? null : h - hDelta < 0 ? h + 360 - hDelta : h - hDelta,
        hMax = h == null ? null : h + hDelta > 360 ? h + hDelta - 360 : h + hDelta,
        sMin = s == null ? null : s - sDelta,
        sMax = s == null ? null : s + sDelta,
        lMin = l == null ? null : l - lDelta,
        lMax = l == null ? null : l + lDelta,
        ratioMin = gRatioMin,
        ratioMax = gRatioMax;

  List<String> queries() {
    List<String> filters = [];
    if (hMin != null || hMax != null) filters.add(rangeQuery("colors.h", hMin, hMax));
    if (sMin != null || sMax != null) filters.add(rangeQuery("colors.s", sMin, sMax));
    if (lMin != null || lMax != null) filters.add(rangeQuery("colors.l", lMin, lMax));
    if (ratioMin != null || ratioMax != null) filters.add(rangeQuery("colors.ratio", ratioMin, ratioMax));
    return ['{"nested": {"path": "colors", "query": {"bool": {"filter": [${filters.join(",")}]}}}}'];
  }
}

class SearchParam {
  String? text;
  SizeParam? size;
  ColorParam? color;
  int skip;
  int limit;

  SearchParam({
    this.text,
    this.size,
    this.color,
    this.skip = 0,
    this.limit = 30,
  });

  String body() {
    List<String> filterQueries = [];
    if (size != null) filterQueries.addAll(size!.queries());
    if (color != null) filterQueries.addAll(color!.queries());
    String? must = text == null ? null : '"must": [{"match": {"labels": "$text"}}]';
    String? filter = filterQueries.isEmpty ? null : '"filter": [${filterQueries.join(",")}]';
    String query = '"query": {"bool": {${[must, filter].where((e) => e != null).join(",")}}}';
    String from = '"from": $skip';
    String sz = '"size": $limit';
    return '{${[from, sz, query].join(",")}}';
  }
}

/*
{
	"query": {
        "bool": {
        	"filter": [
        		{"range": { "width": { "lte": 800 } } },
        		{
					"nested": {
						"path": "colors",
						"query": {
							"bool": {
								"filter": [
									{
										"bool": {
											"should": [
												{"range": { "colors.h": { "lte": 10 } } },
												{"range": { "colors.h": { "gte": 100 } } }
											]
										}
									},
									{"range": { "colors.ratio": { "gte": 0.3 } } }
								]
							}
						}
					}
        		}
			]
        }
    }
}
 */
