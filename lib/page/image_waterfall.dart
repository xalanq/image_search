import 'package:flutter/cupertino.dart';
import 'package:image_search/data/image_data.dart';
import 'package:image_search/model/image_result.dart';
import 'package:image_search/model/search_param.dart';
import 'package:image_search/widget/image_item.dart';
import 'package:image_search/widget/push_to_refresh_header.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:loading_more_list/loading_more_list.dart';

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
    return PullToRefreshNotification(
      pullBackOnRefresh: false,
      armedDragUpCancel: false,
      onRefresh: onRefresh,
      child: LoadingMoreCustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: PullToRefreshContainer(
                (PullToRefreshScrollNotificationInfo? info) {
                return PullToRefreshHeader(info, dateTimeNow);
              }),
          ),
          LoadingMoreSliverList<ImageResult>(
            SliverListConfig<ImageResult>(
              extendedListDelegate:
              const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemBuilder: (context, item, index) => ImageItem(item),
              sourceList: data,
              padding: const EdgeInsets.all(5.0),
              lastChildLayoutType: LastChildLayoutType.foot,
            ),
          )
        ],
      ),
    );
  }

  Future<bool> onRefresh() {
    return data.refresh().whenComplete(() {
      dateTimeNow = DateTime.now();
    });
  }
}