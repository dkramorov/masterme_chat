import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Builder',
      home: Scaffold(
        body: StreamScreen(),
      ),
    );
  }
}

class StreamScreen extends StatefulWidget {

  @override
  _StreamScreenState createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {

  Stream<int> numberStream;

  @override
  void initState() {
    super.initState();
    numberStream = NumberStream().generateNumbers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: numberStream,
        initialData: 0,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error --------------' + snapshot.error);
          }
          if (snapshot.hasData) {
            return Center(
              child: Text(
                snapshot.data.toString(),
                style: TextStyle(fontSize: 50.0),
              ),
            );
          } else {
            return Center(
              child: Text('no data'),
            );
          }
        },
      ),
    );
  }
}


class NumberStream {
  Stream<int> generateNumbers() async* {
    yield* Stream.periodic(Duration(seconds: 1), (int t){
      return Random().nextInt(100);
    });
  }
}