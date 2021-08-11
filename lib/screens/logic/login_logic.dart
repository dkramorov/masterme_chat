import 'dart:async';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/constants.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class LoginScreenLogic {
  static const TAG = 'LoginScreenLogic';

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  Timer loginScreenTimer;

  Function setStateCallback;
  LoginScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;

    this.loginScreenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
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
    List<UserChatModel> users = await UserChatModel.getAllUsers();
    if (users.isEmpty) {
      return;
    }

    curUser = users[users.length - 1];
    openHUD();
    final login = curUser.login.replaceAll('@$JABBER_SERVER', '');
    final passwd = curUser.passwd;
    await authorization(login, passwd);
    setStateCallback({'login': login, 'passwd': passwd});
  }

  /* Втыкаем пользователя в базу */
  Future<void> user2Db(String login, String passwd) async {
    UserChatModel user = await UserChatModel.getByLogin(login);
    if (user == null) {
      user = UserChatModel(
        login: login,
        passwd: passwd,
      );
      await user.insert2Db();
    }

    JabberConn.loggedIn = true;
    JabberConn.curUser = user;
  }

  /* Проверяем состояние экрана авторизации на соответствие JabberConn состоянию */
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser == curUser) {
      return;
    }
    Log.w(TAG, 'STATE CHANGED');
    loggedIn = JabberConn.loggedIn;
    curUser = JabberConn.curUser;

    // Состояние изменилось раз мы тут
    setStateCallback({
      'loggedIn': loggedIn,
    });
  }
}
