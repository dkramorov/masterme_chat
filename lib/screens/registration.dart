import 'dart:async';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';

import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/home.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/chat_registration.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = '/registration_screen/';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const String TAG = 'RegistrationScreen';

  String pageType = 'reg'; // Регистрация или восстановление пароля
  bool loading = false;
  int state = 0; // регистрация
  String login = '8'; // protect from null
  String passwd = ''; // protect from null
  String confirmCode = '';
  final GlobalKey<FormState> _regFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _regConfirmCodeFormKey = GlobalKey<FormState>();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void openHUD() {
    setState(() {
      loading = true;
    });
  }

  void closeHUD() {
    setState(() {
      loading = false;
    });
  }

  /* Регистрация пройдена или
     паролька изменена,
     записываем пользователя
     переходим на главную
   */
  Future<void> userConfirmed() async {
    closeHUD();
    await UserChatModel.insertLastLoginUser(login, passwd);
    Navigator.popUntil(context, ModalRoute.withName(HomeScreen.id));
  }

  /* Отправка формы кода подтверждения
   */
  Future<void> regConfirmCodeFormSubmit() async {
    if (!_regConfirmCodeFormKey.currentState.validate()) {
      return;
    }
    _regConfirmCodeFormKey.currentState.save();

    openHUD();
    state = 2;
    final confirm =
        await RegistrationModel.confirmRegistration(login, confirmCode);
    if (confirm != null && confirm.message != null) {
      if (confirm.code == RegistrationModel.CODE_PASSWD_CHANGED) {
        openInfoDialog(context, userConfirmed, 'Ответ от сервера',
            confirm.message, 'Понятно');
        return;
      } else if (confirm.code == RegistrationModel.CODE_REGISTRATION_SUCCESS) {
        openInfoDialog(context, userConfirmed, 'Ответ от сервера',
            confirm.message, 'Понятно');
        return;
      }
    }
    closeHUD();
  }

  /* Отправка формы регистрации
   */
  Future<void> regFormSubmit() async {
    if (!_regFormKey.currentState.validate()) {
      return;
    }
    _regFormKey.currentState.save();

    openHUD();
    final RegistrationModel reg =
        await RegistrationModel.requestRegistration(login, '', passwd);
    if (reg != null && reg.id != null) {
      state = 1;
    } else {
      openInfoDialog(
          context,
          closeHUD,
          'Ошибка регистрации',
          'Не получен ответ от сервера, пожалуйста, попробуйте поздже',
          'Понятно');
    }
    Log.i(TAG, 'reg: ${reg.toString()}');
    closeHUD();
  }

  Form buildRegConfigrmCodeForm() {
    return Form(
      key: _regConfirmCodeFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'На ваш номер $login должен поступить звонок, прослушайте код подтверждения и введите в поле ниже'),
          SIZED_BOX_H16,
          RoundedInputText(
            hint: 'Код подтверждения',
            onChanged: (String text) {
              setState(() {
                confirmCode = text;
              });
            },
            validator: (String value) {
              bool match = RegExp(r'^[0-9]{4}$').hasMatch(value);
              if (value.isEmpty || !match) {
                return 'Код подтверждения';
              }
            },
            keyboardType: TextInputType.number,
            defaultValue: '',
          ),
          SIZED_BOX_H16,
          RoundedButtonWidget(
            text: Text(
              'Регистрация',
              style: TextStyle(color: Colors.white),
            ),
            color: Colors.green[500],
            onPressed: () {
              regConfirmCodeFormSubmit();
            },
          ),
          SIZED_BOX_H16,
        ],
      ),
    );
  }

  Form buildRegForm() {
    return Form(
      key: _regFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'На ваш номер поступит звонок, прослушайте код, после завершения звонка его надо будет ввести в форму'),
          SIZED_BOX_H16,
          RoundedInputText(
            hint: 'Ваш телефон',
            onChanged: (String text) {
              setState(() {
                login = text;
              });
            },
            formatters: [PhoneFormatter()],
            validator: (String value) {
              bool match = phoneMaskValidator().hasMatch(value);
              if (value.isEmpty || !match) {
                return 'Ваш телефон';
              }
            },
            keyboardType: TextInputType.number,
            defaultValue: login,
          ),
          SIZED_BOX_H16,
          RoundedInputText(
            hint: pageType == 'reg' ? 'Ваш пароль' : 'Новый пароль',
            onChanged: (String text) {
              setState(() {
                passwd = text;
              });
            },
            validator: (String value) {
              if (value.isEmpty) {
                return 'Введите пароль';
              }
            },
            defaultValue: passwd,
          ),
          SIZED_BOX_H16,
          RoundedButtonWidget(
            text: Text(
              'Запросить код',
              style: TextStyle(color: Colors.white),
            ),
            color: Colors.green[500],
            onPressed: () {
              regFormSubmit();
            },
          ),
          SIZED_BOX_H16,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Аргументы доступны только после получения контекста
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {
      pageType = arguments['type'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageType == 'reg' ? 'Регистрация' : 'Сменить пароль',
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 25.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
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
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Text(
                    pageType == 'reg' ? 'Регистрация' : 'Сменить пароль',
                    style: SUBTITLE_STYLE,
                  ),
                ],
              ),
              SIZED_BOX_H16,
              state == 0 ? buildRegForm() : buildRegConfigrmCodeForm(),
            ],
          ),
        ),
      ),
    );
  }
}
