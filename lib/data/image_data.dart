import 'dart:convert';
import 'dart:math';

import 'package:http_client_helper/http_client_helper.dart';
import 'package:image_search/consts.dart';
import 'package:image_search/model/image_result.dart';
import 'package:image_search/model/search_param.dart';
import 'package:loading_more_list/loading_more_list.dart';

class ImageData extends LoadingMoreBase<ImageResult> {
  SearchParam param = SearchParam();
  bool _hasMore = true;
  bool forceRefresh = false;

  ImageData();

  @override
  bool get hasMore => _hasMore || forceRefresh;

  @override
  Future<bool> refresh([bool clearBeforeRequest = false]) async {
    _hasMore = true;
    //force to refresh list when you don't want clear list before request
    //for the case, if your list already has 20 items.
    forceRefresh = !clearBeforeRequest;
    var result = await super.refresh(clearBeforeRequest);
    forceRefresh = false;
    return result;
  }

  @override
  Future<bool> loadData([bool isloadMoreAction = false]) async {
    bool isSuccess = false;
    try {
      String body = param.body();
      final result = await HttpClientHelper.post(
        Uri.parse(Consts.searchURL),
        headers: {
          "content-type": "application/json; charset=utf-8",
        },
        body: body,
      );
      if (result != null) {
        final hits = (jsonDecode(result.body)["hits"] as Map<String, dynamic>)["hits"] as List<dynamic>;
        List<ImageResult> list = [];
        for (final hit in hits) {
          list.add(ImageResult.fromJson((hit as Map<String, dynamic>)["_source"] as Map<String, dynamic>));
        }
        _hasMore = list.isNotEmpty;
        param.skip += min(param.limit, list.length);
        this.addAll(list);
        isSuccess = true;
      }
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
    }
    return isSuccess;
  }
}
