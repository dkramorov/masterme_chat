import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/logic/login_logic.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';
import 'package:masterme_chat/widgets/auth/submit_button.dart';

class SignInForm extends StatefulWidget {
  final LoginScreenLogic logic;
  SignInForm(this.logic);

  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  static const TAG = 'SignInForm';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();

  String login;
  String passwd;

  @override
  void initState() {
    prepareForm();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    passwdController.dispose();
    super.dispose();
  }

  /* Отправка формы авторизации */
  Future<void> loginFormSubmit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    widget.logic.doLogin(login, passwd);
  }

  Future<void> prepareForm() async {
    UserChatModel dbUser = await widget.logic.userFromDb();
    setState(() {
      if (dbUser != null) {
        login = dbUser.getLogin();
        loginController.text = phoneMaskHelper(login);
        passwd = dbUser.passwd;
        passwdController.text = passwd;
        Log.d(TAG, 'set loginController.text=$login');
        Log.d(TAG, 'set passwdController.text=$passwd');
      } else {
        login = '8';
        loginController.text = login;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _formTitleTextStyle = Theme.of(context).textTheme.subtitle1;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Логин (телефон)
          Text(
            SGN_PHONE_TEXT,
            style: _formTitleTextStyle,
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(
              top: 10,
              bottom: 20,
            ),
            child: RoundedInputText(
              hint: SGN_PHONE_TEXT,
              controller: loginController,
              onChanged: (String text) {
                setState(() {
                  login = text;
                });
              },
              formatters: [PhoneFormatter()],
              validator: (String value) {
                bool match = phoneMaskValidator().hasMatch(value);
                if (value.isEmpty || !match) {
                  return 'Например, $SGN_HINT_PHONE_TEXT';
                }
              },
              keyboardType: TextInputType.number,
              defaultValue: login,
            ),
          ),
          Text(
            SGN_PASS_TEXT,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(top: 10, bottom: 30),
            child: RoundedInputText(
              hint: SGN_PASS_TEXT,
              controller: passwdController,
              onChanged: (String text) {
                setState(() {
                  passwd = text;
                });
              },
              validator: (String value) {
                if (value.isEmpty) {
                  return SGN_PASS_TEXT;
                }
              },
              defaultValue: passwd,
            ),
          ),
          Center(
            child: SubmitButton(
              text: SGN_SIGNIN_TEXT,
              onPressed: () {
                loginFormSubmit();
              },
            ),
          ),
        ],
      ),
    );
  }
}
