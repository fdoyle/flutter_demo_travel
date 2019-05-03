import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:grid_experiment_1/Grid.dart';

void main() => runApp(MyApp());

//https://dribbble.com/shots/5384873-Travel-filter-design

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
  AnimationController anim;
  PageController controller;
  double currentPage = 0;

  _MyHomePageState() {
    controller = PageController(viewportFraction: 0.9);
    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        body: SafeArea(
      child: PageView.builder(
          controller: controller,
          itemBuilder: (context, page) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Page(min((currentPage - page).abs(), 1)),
            );
          }),
    ));
  }
}

class Page extends StatelessWidget {
  double delta;

  Page(this.delta);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1-delta*.6,
      child: Grid(
        gapSize: 0,
        columnConstraints: [Fixed(30), Fraction(), Fraction(), Fixed(30)],
        rowAutoConstraint: Auto(),
        rowConstraints: [
          Fixed(30), //top
          Auto(), //nothing+image
          Auto(), //text
          Auto(), //stars+image
          Auto(), //double wide image
        ],
        children: <Widget>[
          GridChild(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                "http://d27k8xmh3cuzik.cloudfront.net/wp-content/uploads/2015/11/extremely-dangerous-adventure-sports.jpg",
                fit: BoxFit.cover,
              ),
            ),
            vStart: Line(2),
            vEnd: Span(3),
            hStart: Line(1),
            hEnd: Span(4),
          ),
          GridChild(
            child: AspectRatio(
              aspectRatio: 1,
              child: MovingImage(
                  "https://images.unsplash.com/photo-1522163182402-834f871fd851?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80",
                  -3 * delta,
                  0),
            ),
            vStart: Line(1),
            vEnd: Span(2),
            hStart: Line(2),
            hEnd: Span(1),
          ),
          GridChild(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Beautiful hiking\ntours\nFour Days",
                style: TextStyle(
                    fontSize: 35,
                    background: Paint()..color = Colors.black38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withAlpha(200)),
              ),
            ),
            vStart: Line(3),
            hStart: Line(2),
            hEnd: Line(5),
          ),
          GridChild(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                Icon(
                  Icons.star_border,
                  color: Colors.white,
                ),
              ],
            ),
            vStart: Line(4),
            hStart: Line(2),
          ),
          GridChild(
            child: AspectRatio(
              aspectRatio: 1,
              child: MovingImage(
                  "http://www.hikinginthesmokys.com/smoky_mountains_photos/mouse-creek-falls/big-creek-2.jpg",
                  0,
                  2*delta),
            ),
            vStart: Line(4),
            hStart: Line(3),
          ),
          GridChild(
            child: AspectRatio(
              aspectRatio: 2,
              child: MovingImage(
                  "https://www.wallpaperup.com/uploads/wallpapers/2015/04/02/653105/09d95a6f0e5f6e6a79bcbc58aa1222ad-700.jpg",
                  0,
                  -2* delta),
            ),
            vStart: Line(5),
            hStart: Line(2),
            hEnd: Span(2),
          ),
        ],
      ),
    );
  }
}

class MovingImage extends StatelessWidget {
  String url;
  double xDelta;
  double yDelta;

  MovingImage(this.url, this.xDelta, this.yDelta);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (ct, constraints) {
        return Transform.translate(
          offset: Offset(
              xDelta * constraints.minWidth, yDelta * constraints.minHeight),
          child: Image.network(
            url,
            fit: BoxFit.cover,
          ),
        );
      }),
    );
  }
}
