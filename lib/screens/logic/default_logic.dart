import 'dart:async';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

abstract class AbstractScreenLogic {
  static const TAG = 'AbstractScreenLogic';

  Function setStateCallback;
  Timer screenTimer;

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  bool isActive = true;

  String getTAG() {
    return TAG;
  }
/*
  AbstractScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();
      Log.d(getTAG(), '${t.tick}');
    });
  }
 */

  Future<void> onTick() async {
    // функция для override
  }

  /* Проверяем состояние экрана ростера на соответствие JabberConn состоянию */
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser == curUser) {
      return;
    }

    Log.w(
        getTAG(), 'STATE CHANGED loggedIn $loggedIn => ${JabberConn.loggedIn}');
    loggedIn = JabberConn.loggedIn;
    curUser = JabberConn.curUser;

    // Состояние изменилось раз мы тут
    if (setStateCallback != null) {
      setStateCallback({'loggedIn': loggedIn, 'curUser': curUser});
      onTick();
    }
  }

  void openHUD() {
    setStateCallback({'loading': true});
  }

  void closeHUD() {
    setStateCallback({'loading': false});
  }

  void deactivate() {
    Log.d(getTAG(), '--- deactivate ---');
    if (this.screenTimer != null) {
      this.screenTimer.cancel();
      this.screenTimer = null;
    }
    isActive = false;
  }

  void dispose() {
    Log.d(getTAG(), '--- dispose ---');
    if (this.screenTimer != null) {
      this.screenTimer.cancel();
      this.screenTimer = null;
    }
    isActive = false;
  }
}
