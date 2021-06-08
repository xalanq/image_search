import 'package:color/color.dart' as convert_color;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_search/data/image_data.dart';
import 'package:image_search/model/image_result.dart';
import 'package:image_search/model/search_param.dart';
import 'package:image_search/widget/image_item.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class ImageWaterfall extends StatefulWidget {
  ImageWaterfall();

  @override
  State<StatefulWidget> createState() => _ImageWaterfallState();
}

class _ImageWaterfallState extends State<ImageWaterfall> {
  ImageData data = ImageData();
  TextEditingController _editingController = TextEditingController();
  Color? color;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingMoreCustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          toolbarHeight: kToolbarHeight + 20,
          titleSpacing: 0,
          title: Center(
            child: Container(
              height: kToolbarHeight,
              padding: EdgeInsets.only(left: 16, right: 16),
              child: TextField(
                controller: _editingController,
                onChanged: (value) {},
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                onSubmitted: (value) {
                  data.param.text = value;
                  data.param.skip = 0;
                  data.refresh(true);
                },
                decoration: InputDecoration(
                  hintText: "Search...",
                  contentPadding: EdgeInsets.only(left: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<SizeParam?>(
              icon: Icon(
                Icons.photo_size_select_actual_outlined,
              ),
              onSelected: (size) {
                data.param.size = size;
                data.param.skip = 0;
                data.refresh(true);
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<SizeParam?>(
                    value: SizeAny,
                    child: Text('Any size'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: SizeSuperLarge,
                    child: Text('Super Large'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: SizeLarge,
                    child: Text('Large'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: SizeMedium,
                    child: Text('Medium'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: SizeSmall,
                    child: Text('Small'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: Size1920x1080,
                    child: Text('1920x1080'),
                  ),
                  PopupMenuItem<SizeParam?>(
                    value: Size1024x768,
                    child: Text('1024x768'),
                  ),
                ];
              },
            ),
            IconButton(
              icon: Icon(
                Icons.palette_outlined,
                color: color,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: color,
                          availableColors: [
                            Colors.red,
                            Colors.pink,
                            Colors.purple,
                            Colors.deepPurple,
                            Colors.indigo,
                            Colors.blue,
                            Colors.lightBlue,
                            Colors.cyan,
                            Colors.teal,
                            Colors.green,
                            Colors.lightGreen,
                            Colors.lime,
                            Colors.yellow,
                            Colors.amber,
                            Colors.orange,
                            Colors.deepOrange,
                            Colors.brown,
                            Colors.white,
                            Colors.grey,
                            Colors.blueGrey,
                            Colors.black,
                          ],
                          onColorChanged: (c) {
                            setState(() {
                              color = c;
                              data.param.skip = 0;
                              if (c == null)
                                data.param.color = null;
                              else {
                                var hsl = convert_color.Color.rgb(c.red, c.green, c.blue).toHslColor();
                                data.param.color =
                                    ColorParam.color(hsl.h.toDouble(), hsl.s.toDouble() / 100, hsl.l.toDouble() / 100);
                                if (c == Colors.black) data.param.color = ColorParam.color(null, null, 0.0);
                                if (c == Colors.white) data.param.color = ColorParam.color(null, null, 1);
                              }
                              data.refresh(true);
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(width: 16),
          ],
        ),
        LoadingMoreSliverList<ImageResult>(
          SliverListConfig<ImageResult>(
            extendedListDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              collectGarbage: (List<int> garbages) {
                garbages.forEach((index) {
                  final provider = ExtendedNetworkImageProvider(
                    data[index].imageURL,
                  );
                  provider.evict();
                });
              },
            ),
            itemBuilder: (context, item, index) => ImageItem(item),
            sourceList: data,
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            lastChildLayoutType: LastChildLayoutType.foot,
          ),
        )
      ],
    );
  }
}
