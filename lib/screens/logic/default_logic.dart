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

  String getTAG() {
    return TAG;
  }

  AbstractScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  Future<void> onTick() async {
    // функция для override
  }

  /* Проверяем состояние экрана ростера на соответствие JabberConn состоянию */
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser == curUser) {
      return;
    }
    Log.w(getTAG(), 'STATE CHANGED loggedIn $loggedIn => ${JabberConn.loggedIn}');
    loggedIn = JabberConn.loggedIn;
    curUser = JabberConn.curUser;

    // Состояние изменилось раз мы тут
    setStateCallback({'loggedIn': loggedIn});
    onTick();
  }
}