import 'package:flutter/material.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';

import '../constants.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = '/registration_screen/';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Регистрация',
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
                    'Регистрация',
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
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  RoundedInputText(
                    text: 'Ваш пароль',
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
