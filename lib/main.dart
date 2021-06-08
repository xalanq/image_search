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
      text: "dog",
      color: ColorParam.color(52, 0.1, 0.85),
      // size: Size1024x768,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ImageWaterfall(param),
    );
  }
}
