import 'dart:async';
import 'package:flutter/material.dart';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/constants.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class LoginScreenLogic extends AbstractScreenLogic {
  static const TAG = 'LoginScreenLogic';

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  // Если приехало пуш уведомление,
  // то мы через экран авторизации
  // должны выбрать нужный чат
  String pushFrom;
  String pushTo;

  LoginScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  /* Выход */
  logout() async {
    JabberConn.clear();
    setStateCallback({'loading': false, 'loggedIn': false, 'autoLogin': false});
    checkState();
  }

  Future<void> authorization(String login, String passwd) async {
    xmpp.Jid jid;

    final fullLogin =
        login.replaceAll(RegExp('[^0-9]+'), '') + '@' + JABBER_SERVER;

    try {
      jid = xmpp.Jid.fromFullJid(fullLogin);
    } catch (e) {
      print(e);
      return;
    }
    openHUD();
    xmpp.XmppAccountSettings account = xmpp.XmppAccountSettings(
      fullLogin,
      jid.local,
      jid.domain,
      passwd,
      JABBER_PORT,
    );
    JabberConn.createConnection(account);
    setStateCallback({
      'listenConnectionStream': true,
      'login': login,
      'passwd': passwd,
    });
  }

  /* Вытаскиваем пользователя из базы (последнего)
     предполагаем работу функции через FutureBuilder
  */
  Future<UserChatModel> userFromDb() async {
    if (JabberConn.connection != null && JabberConn.connection.authenticated) {
      Log.d(TAG, 'already connected ${JabberConn.curUser.login}');
      return JabberConn.curUser;
    }
    UserChatModel dbUser = await UserChatModel.getLastLoginUser();
    if (dbUser == null) {
      Log.d(TAG, 'there is no user id db');
      return null;
    }
    Log.d(TAG, 'user found ${dbUser.login}');
    //openHUD();
    final login = dbUser.getLogin();
    final passwd = dbUser.passwd;
    //await authorization(login, passwd);
    //setStateCallback({'login': login, 'passwd': passwd});
    return dbUser;
  }

  /* Авторизация */
  Future<void> doLogin(String login, String passwd) async {
    if (login != null && login != '' && passwd != null && passwd != '') {
      openHUD();
      await authorization(login, passwd);
    }
  }

  /* Втыкаем пользователя в базу */
  static Future<void> user2Db(String login, String passwd) async {
    JabberConn.curUser = await UserChatModel.insertLastLoginUser(login, passwd);
  }

  /* Если приходило пушь уведомление,
     у нас есть данные от кого=>кому
     в случае перехода на чат, надо попытаться
     сразу открыть чат с "от кого"
   */
  Map<String, String> getPushArguments() {
    Map<String, String> arguments = {};
    if (pushFrom != null && pushTo != null) {
      return {'from': pushFrom, 'to': pushTo};
    }
    return null;
  }

  /* Получение аргументов на вьюхе (пушь уведомление) */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {
      String payload = arguments['payload'];
      if (payload != null && payload.contains('=>')) {
        List<String> result = payload.split('=>');
        pushFrom = result[0];
        pushTo = result[1];
      }
    }
  }

  /* Пришло событие xmpp.XmppConnectionState.Ready */
  Future<void> authorizationSuccess(String login, String passwd) async {
    await user2Db(login, passwd);
    JabberConn.sendToken();
    //checkState();
    closeHUD();
  }
}
