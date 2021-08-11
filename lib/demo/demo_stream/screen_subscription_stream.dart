import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

const TextStyle textStyle = TextStyle(
  fontSize: 25.0,
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Stream',
      home: Scaffold(
        body: SubscriptionScreen(),
      ),
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  StreamSubscription subscription;
  StreamSubscription subscription2;

  StreamContainer streamContainer;
  StreamController streamController;
  String prevLetter;

  addWord2Sink() {
    if (streamController.isClosed) {
      print('Already closed');
      //return;
    }
    List<String> texts = [
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eight',
      'ninth',
      'ten',
    ];
    int index = Random().nextInt(texts.length);
    streamContainer.add2Sink(texts[index]);
  }

  @override
  void initState() {
    super.initState();
    streamContainer = StreamContainer();
    streamController = streamContainer.controller;
    //Stream stream = subscriptionStreamController.stream; // Один слушатель
    Stream stream = streamController.stream.asBroadcastStream(); // Мультиподписка

    subscription = stream.listen((event) {
      setState(() {
        prevLetter = event;
      });
    });

    subscription.onError((err){
      setState(() {
        prevLetter = 'err';
      });
    });

    subscription.onDone(() {
      setState(() {
        prevLetter = 'DONE!';
      });
    });

    subscription2 = stream.listen((event) {
      setState(() {
        prevLetter = event + '----';
      });
    });
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
              prevLetter.toString(),
              style: textStyle,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              addWord2Sink();
            },
            child: Text(
              'new letter',
              style: textStyle,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              streamContainer.addError2Sink();
            },
            child: Text(
              'new error',
              style: textStyle,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              streamContainer.close();
            },
            child: Text(
              'stop stream',
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class StreamContainer {
  StreamController<String> controller = StreamController<String>();

  void add2Sink(String text) {
    if (controller.isClosed) {
      print('already closed');
      return;
    }
    controller.sink.add(text);
  }

  void addError2Sink() {
    if (controller.isClosed) {
      print('already closed');
      return;
    }
    controller.sink.addError('addError2Sink');
  }

  void close() {
    controller.sink.close();
  }
}
