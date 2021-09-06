import 'dart:async';
import 'package:flutter/material.dart';

import 'package:masterme_chat/db/user_chat_model.dart';
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
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  void openHUD() {
    setStateCallback({'loading': true});
  }

  void closeHUD() {
    setStateCallback({'loading': false});
  }

  /* Выход */
  logout() async {
    JabberConn.clear();
    setStateCallback({'loading': false, 'loggedIn': false});
    checkState();
  }

  Future<void> authorization(String login, String passwd) async {
    xmpp.Jid jid;

    final fullLogin =
        login.replaceAll(RegExp('[^0-9]+'), '') + '@' + JABBER_SERVER;
    openHUD();
    try {
      jid = xmpp.Jid.fromFullJid(fullLogin);
    } catch (e) {
      print(e);
      return;
    }
    xmpp.XmppAccountSettings account = xmpp.XmppAccountSettings(
      fullLogin,
      jid.local,
      jid.domain,
      passwd,
      JABBER_PORT,
    );
    JabberConn.createConnection(account);
  }

  /* Вытаскиваем пользователя из базы (последнего) */
  Future<void> userFromDb() async {
    if (JabberConn.connection != null && JabberConn.connection.authenticated) {
      return;
    }
    UserChatModel curUser = await UserChatModel.getLastLoginUser();
    if (curUser == null) {
      return;
    }
    openHUD();
    final login = curUser.login.replaceAll('@$JABBER_SERVER', '');
    final passwd = curUser.passwd;
    await authorization(login, passwd);
    setStateCallback({'login': login, 'passwd': passwd});
  }

  /* Втыкаем пользователя в базу */
  static Future<void> user2Db(String login, String passwd) async {
    UserChatModel user = await UserChatModel.insertLastLoginUser(login, passwd);
    JabberConn.loggedIn = true;
    JabberConn.curUser = user;
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
}
