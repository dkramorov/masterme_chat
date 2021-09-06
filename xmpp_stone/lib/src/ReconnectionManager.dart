import 'dart:async';
import 'package:xmpp_stone/src/Connection.dart';
import 'logger/Log.dart';

class ReconnectionManager {
  static const TAG = 'ReconnectionManager';

  // Флаг активации ставим после соединения,
  // нах надо сразу то переподключаться,
  // может пароль неправильный, может сервер
  bool isActive = false;
  Connection _connection;
  int timeOutInMs = 10000;
  int counter = 0;
  Timer timer;

  ReconnectionManager(Connection connection) {
    _connection = connection;
    _connection.connectionStateStream.listen(connectionStateHandler);
  }

  void connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.ForcefullyClosed) {
      if (!isActive) {
        return;
      }
      // connection lost
      Log.d(TAG, 'Connection forcefully closed!');
      handleReconnection();
    } else if (state == XmppConnectionState.SocketOpening) {
      //do nothing
    } else if (state != XmppConnectionState.Reconnecting) {
      counter = 0;
      if (timer != null) {
        timer.cancel();
        timer = null;
      }
    }
  }

  void handleReconnection() {
    if (timer != null) {
      timer.cancel();
    }
    if (counter > _connection.account.totalReconnections){
      Log.w(TAG, 'Reconnection manager drop white flag and surrender');
      isActive = false;
      return;
    }
    timer = Timer(Duration(milliseconds: timeOutInMs), _connection.reconnect);
    Log.d(TAG, 'reconnection $counter, timeOut: $timeOutInMs ');
    counter++;
    // Несколько раз попробуем и нах оно надо
  }
}
