import 'dart:convert';

import 'package:color/color.dart' as convert_color;
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_search/consts.dart';
import 'package:image_search/model/image_result.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class ImageItem extends StatefulWidget {
  final ImageResult image;

  ImageItem(this.image, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final imageURL = path.join(Consts.imageHost, image.path);
    print(image.title + " " + jsonEncode(image.colors[0]));
    final dominantColor =
        convert_color.HslColor(image.colors[0].h, image.colors[0].s * 100, image.colors[0].l * 100).toRgbColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: AspectRatio(
            aspectRatio: image.width / image.height,
            child: ExtendedImage.network(
              imageURL,
              // image.url,
              shape: BoxShape.rectangle,
              //clearMemoryCacheWhenDispose: true,
              loadStateChanged: (ExtendedImageState value) {
                if (value.extendedImageLoadState == LoadState.loading) {
                  return Container(
                    color: Color.fromRGBO(dominantColor.r.toInt(), dominantColor.g.toInt(), dominantColor.b.toInt(), 1),
                  );
                }
                return null;
              },
            ),
          ),
          onTap: () {
            launch(imageURL);
          },
        ),
        SizedBox(height: 5),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExtendedText(
                image.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                onTap: () {
                  launch(image.landingURL);
                },
              ),
              SizedBox(height: 5),
              ExtendedText(
                image.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  launch(image.landingURL);
                },
              ),
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
