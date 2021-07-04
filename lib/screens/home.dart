import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/login.dart';
import 'package:masterme_chat/screens/registration.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';

import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
/*
// websocket
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as WS_STATUS;

Future<IOWebSocketChannel> ws_connect() async {
  final String WS_ADDR = 'wss://anhel.1sprav.ru/wss/';
  //final channel = await IOWebSocketChannel.connect(WS_ADDR);
  final channel = await WebSocketChannel.connect(Uri.parse(WS_ADDR));

  channel.stream.listen((message) {
    //channel.sink.add('received!');
    //channel.sink.close(status.goingAway);
    print(message);
  });

  final String cmd = "<open xmlns='urn:ietf:params:xml:ns:xmpp-framing' to='anhel.1sprav.ru' version='1.0'/>";
  channel.sink.add(cmd);


  return channel;
}
*/

class HomeScreen extends StatefulWidget {
  // Обязательно '/' без него завалится все нахер
  static const String id = '/';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  AnimationController animController;

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    xmpp.XmppAccountSettings account = xmpp.XmppAccountSettings("jocker", "jocker", "anhel.1sprav.ru", "Cnfylfhnysq1", 5222);
    xmpp.Connection connection = new xmpp.Connection(account);
    connection.connect();

    animController = AnimationController(
      duration: Duration(
        seconds: 1,
      ),
      vsync: this,
      upperBound: LOGO_SIZE,
    );
    animController.forward();
    animController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ЧАТ',
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 25.0,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: 15.0,
                    ),
                    child: Hero(
                      tag: LOGO_ICON_TAG,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: animController.value,
                      ),
                    ),
                  ),
                  Text(
                    LOGO_NAME,
                    style: SUBTITLE_STYLE,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 15.0,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                    ),
                    child: RoundedButtonWidget(
                      text: Text('Авторизация'),
                      color: Colors.lightBlue[900],
                      onPressed: () {
                        Navigator.pushNamed(context, LoginScreen.id);
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 10.0,
                    ),
                    child: RoundedButtonWidget(
                      text: Text('Регистрация'),
                      color: Colors.blueAccent[900],
                      onPressed: () {
                        Navigator.pushNamed(context, RegistrationScreen.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
