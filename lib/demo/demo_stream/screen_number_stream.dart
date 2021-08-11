import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Stream',
      home: Scaffold(
        body: NumberScreen(),
      ),
    );
  }
}

class NumberScreen extends StatefulWidget {
  @override
  _NumberScreenState createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  int prevNumber;
  NumberStream numberStream;
  StreamController numberStreamController;
  StreamTransformer numberStreamTransformer;

  @override
  void initState() {
    super.initState();

    numberStreamTransformer = StreamTransformer<int, dynamic>.fromHandlers(
      handleData: (value, sink) {
        sink.add(value - value * 2);
      },
      handleError: (error, trace, sink) {
        sink.add(-1);
      },
      handleDone: (sink) {
        sink.close();
      }
    );

    numberStream = NumberStream();
    numberStreamController = numberStream.controller;

    Stream stream = numberStreamController.stream;
    //stream.listen((event) { // Без трансформеров
    stream.transform(numberStreamTransformer).listen((event) { // С трансформером
      setState(() {
        prevNumber = event;
      });
    }).onError((error) {
      setState(() {
        prevNumber = -1;
      });
    });
  }

  @override
  void dispose() {
    numberStreamController.close();
    numberStream.close();
    super.dispose();
  }

  void add2Stream() {
    int digit = Random().nextInt(1000);
    numberStream.addToSink(digit);
  }

  void addError2Stream() {
    numberStream.addError('addError2Stream');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(
              prevNumber.toString(),
              style: TextStyle(
                fontSize: 50.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              add2Stream();
            },
            child: Text(
              'New number',
              style: TextStyle(
                fontSize: 30.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              addError2Stream();
            },
            child: Text(
              'New error',
              style: TextStyle(
                fontSize: 30.0,
              ),
            )
          )
        ],
      ),
    );
  }
}

class NumberStream {
  StreamController<int> controller = StreamController<int>();

  void addToSink(int digit) {
    controller.sink.add(digit);
  }

  void addError(String err) {
    controller.sink.addError(err);
  }

  void close() {
    controller.close();
  }
}
