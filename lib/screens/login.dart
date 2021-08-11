import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/roster.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

import 'logic/login_logic.dart';

class LoginScreen extends StatefulWidget {
  static const String id = '/login_screen/';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const TAG = 'LoginScreen';
  LoginScreenLogic logic;

  // Переменные JabberConn для отслеживания изменения состояния
  bool loggedIn = false;
  int connectionInstanceKey = 0;

  bool loading = false;
  String login = '8'; // protect from null
  String passwd = ''; // protect from null
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String jabberServer;

  StreamSubscription connectionSubscription;

  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();

  final connectionErrorSnackBar = SnackBar(
    content: Text(
      'Не удается установить соединение, проверьте адрес сервера или подключение к интернет сети',
    ),
  );

  @override
  void dispose() {
    loginController.dispose();
    passwdController.dispose();

    if (connectionSubscription != null) {
      connectionSubscription.cancel();
    }
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /* Отправка формы авторизации
     либо выход, если авторизован
  */
  Future<void> loginFormSubmit() async {
    if (loggedIn) {
      logic.closeHUD();
      Navigator.pushNamed(context, RosterScreen.id);
      return;
    }
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    await logic.authorization(login, passwd);
    listenConnectionStream();
  }

  /* Слушаем состояние подключения */
  Future<void> listenConnectionStream() async {
    if (connectionSubscription != null) {
      if (connectionInstanceKey != JabberConn.instanceKey) {
        connectionSubscription.cancel();
        Log.d(TAG, 'connectionSubscription cancel');
      } else {
        Log.d(TAG, 'connectionSubscription exists');
        return;
      }
    }
    Log.d(TAG, 'connectionSubscription new');
    connectionInstanceKey = JabberConn.instanceKey;

    connectionSubscription = JabberConn.connectionStream.listen((event) {
      if (event == xmpp.XmppConnectionState.Ready) {
        // Только если мы на этой страничке
        // Записываем в базень логин пароль
        logic.checkState();
        if (ModalRoute.of(context).isCurrent) {
          logic.user2Db(login, passwd).then((success) {
            JabberConn.sendToken();
            logic.checkState();
            logic.closeHUD();
            Navigator.pushNamed(context, RosterScreen.id);
          });
        }
      } else if (event == xmpp.XmppConnectionState.AuthenticationFailure) {
        if (ModalRoute.of(context).isCurrent) {
          openInfoDialog(context, logic.closeHUD, 'Ошибка авторизации',
              'Неправильный логин или пароль', 'Понятно');
        }
        // Удаляем такого пользователя если он есть в базе
        UserChatModel.dropByLogin(login);
        logic.checkState();
      } else if (event == xmpp.XmppConnectionState.ForcefullyClosed) {
        // Можно перейти на таймер
        logic.closeHUD();
        logic.checkState();
      }
    });
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['loading'] != null && state['loading'] != loading) {
        loading = state['loading'];
      }
      if (state['loggedIn'] != null && state['loggedIn'] != loggedIn) {
        loggedIn = state['loggedIn'];
      }
      if (state['login'] != null && state['login'] != login) {
        login = state['login'];
        loginController.text = phoneMaskHelper(login);
      }
      if (state['passwd'] != null && state['passwd'] != passwd) {
        passwd = state['passwd'];
        passwdController.text = passwd;
      }
    });

    if (loggedIn) {
      listenConnectionStream();
    }
  }

  Future<void> prepareConnection() async {
    await logic.userFromDb();
    listenConnectionStream();
  }

  @override
  void initState() {
    logic = LoginScreenLogic(setStateCallback: setStateCallback);
    prepareConnection();
    super.initState();
  }

  Widget loginInputOrLoginText() {
    return loggedIn
        ? Center(
            child: Text(
              'Вы авторизованы:\n' + JabberConn.connection.fullJid.local,
              style: GREEN_TEXT_STYLE,
            ),
          )
        : RoundedInputText(
            hint: 'Ваш Логин',
            controller: loginController,
            onChanged: (String text) {
              setState(() {
                login = text;
              });
            },
            formatters: [PhoneFormatter()],
            validator: (String value) {
              bool match =
                  RegExp(r'^8 \([0-9]{3}\) [0-9]{1}-[0-9]{3}-[0-9]{3}$')
                      .hasMatch(value);
              if (value.isEmpty || !match) {
                return 'Ваш телефон';
              }
            },
            keyboardType: TextInputType.number,
            defaultValue: login,
          );
  }

  @override
  Widget build(BuildContext context) {
    logic.checkState();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Авторизация',
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 40.0,
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
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: LOGO_SIZE,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Авторизация',
                        style: SUBTITLE_STYLE,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        loginInputOrLoginText(),
                        SizedBox(
                          height: 15.0,
                        ),
                        Visibility(
                          visible: !loggedIn,
                          child: RoundedInputText(
                            hint: 'Ваш пароль',
                            controller: passwdController,
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
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        RoundedButtonWidget(
                          text: Text(
                            'Вход',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.green[500],
                          onPressed: () {
                            loginFormSubmit();
                          },
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        Visibility(
                          visible: loggedIn,
                          child: RoundedButtonWidget(
                            text: Text(
                              'Выход',
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Colors.green[500],
                            onPressed: () {
                              logic.logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
