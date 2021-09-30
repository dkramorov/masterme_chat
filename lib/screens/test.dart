import 'package:flutter/material.dart';
import 'package:masterme_chat/demo/chat_variant2/chats.dart';

class TestScreen extends StatefulWidget {
  static const String id = '/test_screen/';

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TEST',
        ),
      ),
      body: Container(
        //child: Text('test screen'),
        child: Chats(), // Вариант дизайна для странички ростера и чата
      ),
    );
  }
}
