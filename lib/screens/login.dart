import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';

class LoginScreen extends StatefulWidget {
  static const String id = '/login_screen/';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String login;
  String passwd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Авторизация',
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 25.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                        size: LOGO_SIZE,
                      ),
                    ),
                  ),
                  Text(
                    'Авторизация',
                    style: SUBTITLE_STYLE,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    height: 15.0,
                  ),
                  RoundedInputText(
                    text: 'Ваш Email',
                    onChanged: (String text) {
                      login = text;
                    },
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  RoundedInputText(
                    text: 'Ваш пароль',
                    onChanged: (String text) {
                      passwd = text;
                    },
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  RoundedButtonWidget(
                    text: Text('Вход'),
                    color: Colors.lightBlue[900],
                    onPressed: () {
                      print('$login : $passwd');
                    },
                  )
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
