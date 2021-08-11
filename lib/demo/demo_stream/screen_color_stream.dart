import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Stream',
      home: Scaffold(
        body: ColorScreen(),
      ),
    );
  }
}

class ColorScreen extends StatefulWidget {
  @override
  _ColorScreenState createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  Color bgColor = Colors.pink;
  Color bgColor2 = Colors.pink;
  ColorStream colorStream;
  ColorStream colorStream2;

  changeColor() async {
    await for (var eventColor in colorStream.getColors()) {
      setState(() {
        bgColor = eventColor;
      });
    }
    // Код не выполнится пока стрим идет
    print('Stream 1');
  }

  void changeColor2() {
    colorStream2.getColors().listen((color2) {
      setState(() {
        bgColor2 = color2;
      });
    });
    // Код выполнится пока стрим идет
    print('Stream 2');
  }

  @override
  void initState() {
    super.initState();

    // Color stream 1
    colorStream = ColorStream();
    changeColor();

    // Color stream 2
    colorStream2 = ColorStream();
    changeColor2();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: Container(
          color: bgColor,
        ),
      ),
      SizedBox(
        height: 10.0,
      ),
      Expanded(
        child: Container(
          color: bgColor2,
        ),
      ),
    ]);
  }
}

class ColorStream {
  final List<Color> colors = [
    Colors.blueGrey,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.teal,
  ];
  Stream colorStream;
  Stream<Color> getColors() async* {
    yield* Stream.periodic(Duration(seconds: 1), (int t) {
      int index = t % 5;
      return colors[index];
    });
  }
}
