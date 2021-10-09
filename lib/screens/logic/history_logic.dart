import 'dart:async';

import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

class HistoryScreenLogic extends AbstractScreenLogic {
  static const TAG = 'HistoryScreenLogic';

  HistoryScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    checkState();

    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  Future<void> loadHistory() async {
    List<UserHistoryModel> history = await UserHistoryModel.getAllHistory(JabberConn.curUser.login);
    setStateCallback({
      'history': history,
    });
  }

}
