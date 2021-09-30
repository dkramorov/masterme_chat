import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/auth/reg_links.dart';
import 'package:masterme_chat/widgets/auth/sign_out_form.dart';
import 'package:masterme_chat/widgets/auth/sign_in_form.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/screens/logic/login_logic.dart';
import 'package:masterme_chat/helpers/log.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class AuthScreen extends StatefulWidget {
  static const String id = '/auth_screen/';

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const TAG = 'AuthScreen';
  static const _HEADER_IMAGE = 'assets/svg/bp_header_login.svg';
  bool loading = false; // HUD
  bool autoLogin = true;
  StreamSubscription connectionSubscription;
  LoginScreenLogic logic;

  // Форма авторизации
  String login;
  String passwd;

  // JabberConn для отслеживания изменения состояния
  bool loggedIn = false;
  int connectionInstanceKey = 0;

  final connectionErrorSnackBar = SnackBar(
    content: Text(
      'Не удается установить соединение,' +
          'проверьте адрес сервера или подключение к интернет сети',
    ),
  );

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    if (connectionSubscription != null) {
      connectionSubscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    logic = LoginScreenLogic(setStateCallback: setStateCallback);
    super.initState();
  }

  void gotoRootScreen() {
    // setState() or markNeedsBuild called during build (без delayed)
    // если вызывать раньше чем закончится build
    Future.delayed(Duration.zero, () async {
      Navigator.pop(context);
      /*
      Navigator.pushNamed(context, RootScreen.id, //RosterScreen.id,
          arguments: logic.getPushArguments());
       */
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

        // Переадресация по пушу TODO: убрать отсюда
        if (ModalRoute.of(context).isCurrent) {
          if (logic.pushTo != null && logic.pushFrom != null) {
            gotoRootScreen();
          }
        }
      }
      if (state['autoLogin'] != null && state['autoLogin'] != autoLogin) {
        autoLogin = state['autoLogin'];
      }
      if (state['login'] != null && state['login'] != login) {
        login = state['login'];
        Log.d(TAG, 'setState new login=$login');
      }
      if (state['passwd'] != null && state['passwd'] != passwd) {
        passwd = state['passwd'];
        Log.d(TAG, 'setState new passwd=$passwd');
      }
      if (state['autoLogin'] != null && state['autoLogin'] != autoLogin) {
        autoLogin = state['autoLogin'];
      }
    });
    if (state['listenConnectionStream'] != null &&
        state['login'] != null &&
        state['passwd'] != null) {
      login = state['login'];
      passwd = state['passwd'];
      listenConnectionStream();
    } else if (loggedIn) {
      listenConnectionStream();
    }
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
        if (mounted && ModalRoute.of(context).isCurrent) {
          logic.authorizationSuccess(login, passwd).then((success) {
            gotoRootScreen();
          });
        }
      } else if (event == xmpp.XmppConnectionState.AuthenticationFailure) {
        if (ModalRoute.of(context).isCurrent) {
          openInfoDialog(context, logic.closeHUD, 'Ошибка авторизации',
              'Неправильный логин или пароль', 'Понятно');
        }
        logic.checkState();
      } else if (event == xmpp.XmppConnectionState.ForcefullyClosed) {
        logic.closeHUD();
        logic.checkState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _sgnTitleTextStyle = Theme.of(context).textTheme.headline4;
    logic.checkState();
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    _HEADER_IMAGE,
                    alignment: Alignment.bottomCenter,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: PAD_SYM_H30,
                  child: Center(
                    child: Column(
                      children: [
                        SIZED_BOX_H30,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              child: Image(
                                image: AssetImage('assets/misc/icon.png'),
                                height: 80.0,
                                fit: BoxFit.fill,
                              ),
                            ),
                            loggedIn
                                ? Container(
                                    margin: PAD_SYM_V20,
                                    child: Text(
                                      LOGO_NAME,
                                      style: _sgnTitleTextStyle,
                                    ),
                                  )
                                : Container(
                                    margin: PAD_SYM_V20,
                                    child: Text(
                                      SGN_SIGNIN_TEXT,
                                      style: _sgnTitleTextStyle,
                                    ),
                                  ),
                          ],
                        ),
                        SIZED_BOX_H30,
                        loggedIn ? SignOutForm(logic) : SignInForm(logic),
                        loggedIn ? Container() : RegLinks(logic),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
