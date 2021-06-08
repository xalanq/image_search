import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_search/data/image_data.dart';
import 'package:image_search/model/image_result.dart';
import 'package:image_search/model/search_param.dart';
import 'package:image_search/widget/image_item.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class ImageWaterfall extends StatefulWidget {
  final SearchParam param;

  ImageWaterfall(this.param);

  @override
  State<StatefulWidget> createState() => _ImageWaterfallState();
}

class _ImageWaterfallState extends State<ImageWaterfall> {
  late ImageData data;
  DateTime? dateTimeNow;

  @override
  void initState() {
    super.initState();
    data = ImageData(widget.param);
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
            title: Text("MultipleSliverDemo"),
          ),
          LoadingMoreSliverList<ImageResult>(
            SliverListConfig<ImageResult>(
              extendedListDelegate:
              const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, item, index) => ImageItem(item),
              sourceList: data,
              padding: const EdgeInsets.all(5.0),
              lastChildLayoutType: LastChildLayoutType.foot,
            ),
          )
        ],
    );
  }

  Future<bool> onRefresh() {
    return data.refresh().whenComplete(() {
      dateTimeNow = DateTime.now();
    });
  }
}