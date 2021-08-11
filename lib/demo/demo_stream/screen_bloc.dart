import 'package:flutter/material.dart';

import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLoC',
      home: Scaffold(
        body: BLoCScreen(),
      ),
    );
  }
}

class BLoCScreen extends StatefulWidget {
  @override
  _BLoCScreenState createState() => _BLoCScreenState();
}

class _BLoCScreenState extends State<BLoCScreen> {
  int seconds;
  CountDownBLoC sBLoC;

  @override
  void dispose() {
    super.dispose();
    sBLoC.dispose();
  }

  @override
  void initState() {
    super.initState();
    sBLoC = CountDownBLoC();
    seconds = sBLoC.seconds;
    sBLoC.countDown();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: sBLoC.stream,
        initialData: seconds,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('[ERROR]: ${snapshot.error}');
          }
          if (snapshot.hasData) {
            return Center(
              child: Text(
                snapshot.data.toString(),
                style: TextStyle(fontSize: 30.0),
              ),
            );
          } else {
            return Center(
              child: Text('no data'),
            );
          }
        },
    );
  }
}

class CountDownBLoC {
  int seconds = 60;
  final StreamController _controller = StreamController();

  Stream get stream => _controller.stream.asBroadcastStream(); // getter
  StreamSink get sink => _controller.sink; // getter

  Future<void> descreaseSeconds() async {
    Future.delayed(Duration(seconds: 1)); // just delay
    seconds -= 1;
    sink.add(seconds);
  }

  void countDown() async {
    for (int i = seconds; i > 0; i--) {
      await descreaseSeconds();
    }
  }

  void dispose() {
    _controller.close();
  }
}
