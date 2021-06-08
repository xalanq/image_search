import 'package:flutter/material.dart';
import 'package:image_search/model/search_param.dart';
import 'package:image_search/page/image_waterfall.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    var param = SearchParam(
      text: "cat",
      // color: ColorParam.color(null, null, 1),
      // size: Size1024x768,
    );
    return Scaffold(
      body: ImageWaterfall(param),
    );
  }
}
