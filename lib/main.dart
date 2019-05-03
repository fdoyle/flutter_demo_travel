import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fast_noise/fast_noise.dart';
import 'package:grid_experiment_1/Grid.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Grid(
          columnConstraints: [Fixed(150), Fraction(), Fixed(150)],
          rowAutoConstraint: Auto(),
//          rowConstraints: [
//            Fixed(150),
//            Fixed(150),
//          ],
          children: <Widget>[
            GridChild(child: TestWidget(color: Colors.red), vStart: Line(1), vEnd:Span(3), hStart: Line(1), hEnd:Span(3),),
            GridChild(child: Text("Foo"), vStart: Line(1), vEnd:Span(1), hStart: Line(1), hEnd:Span(2),),
            GridChild(child: TestWidget(color: Colors.blue.withAlpha(100)), vStart: Line(2), vEnd:Span(2), hStart: Line(1), hEnd:Span(2),),
            GridChild(child: TestWidget(color: Colors.blue.withAlpha(100)), vStart: Line(1), vEnd:Span(2), hStart: Line(2), hEnd:Span(2),),

            GridChild(child: Text("Bar"), vStart: Line(2), vEnd:Span(1), hStart: Line(1), hEnd:Span(2),),

            GridChild(child: TestWidget(color: Colors.green)),
            GridChild(child: TestWidget(color: Colors.grey)),
            GridChild(child: TestWidget(color: Colors.orange)),
            GridChild(child: TestWidget(color: Colors.purple)),
            GridChild(child: TestWidget(color: Colors.blueGrey)),
            GridChild(child: TestWidget(color: Colors.yellow)),
            GridChild(child: TestWidget(color: Colors.cyan)),
          ],
        ));
  }
}

class TestWidget extends StatelessWidget {
  Color color;


  TestWidget({this.color});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: (){
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('clicked $color'),
            ));
          print(color);
        },
        child: Container(color:color),
      ),
    );
  }
}