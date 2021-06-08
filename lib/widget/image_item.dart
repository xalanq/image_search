import 'dart:math';

import 'package:color/color.dart' as convert_color;
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_search/model/image_result.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageItem extends StatefulWidget {
  final ImageResult image;

  ImageItem(this.image, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageItemState();
}

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
}

class _ImageItemState extends State<ImageItem> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final dominantColor =
        convert_color.HslColor(image.colors[0].h, image.colors[0].s * 100, image.colors[0].l * 100).toRgbColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          child: Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: image.width / image.height,
                child: ExtendedImage.network(
                  image.imageURL,
                  shape: BoxShape.rectangle,
                  //clearMemoryCacheWhenDispose: true,
                  loadStateChanged: (ExtendedImageState value) {
                    if (value.extendedImageLoadState == LoadState.loading) {
                      return Container(
                        color: Color.fromRGBO(
                            dominantColor.r.toInt(), dominantColor.g.toInt(), dominantColor.b.toInt(), 1),
                      );
                    }
                    return null;
                  },
                ),
              ),
              if (_isHover)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: 0.6,
                    child: Container(
                      color: Colors.black,
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      child: Text(
                        '${image.width}x${image.height}  ${formatBytes(image.size, 2)}',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isHover)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      '${image.width}x${image.height}  ${formatBytes(image.size, 2)}',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            launch(image.imageURL);
          },
          onHover: (value) {
            setState(() {
              _isHover = value;
            });
          },
        ),
        InkWell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              ExtendedText(
                image.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                onTap: () {
                  launch(image.landingURL);
                },
              ),
              SizedBox(height: 5),
              ExtendedText(
                Uri.parse(image.landingURL).host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
                onTap: () {
                  launch(image.landingURL);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
          onTap: () {
            launch(image.landingURL);
          },
        ),
        SizedBox(height: 5),
      ],
    );
  }
}
