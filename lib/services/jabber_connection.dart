import 'dart:async';

import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';

import 'package:http/http.dart' as http;
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class JabberConn {
  static const String TAG = 'JabberConn';

  static int instanceKey = 0;
  static Timer healthCheckTimer;
  static xmpp.XmppAccountSettings restoreAccount;

  static String receiver;
  static String TOKEN_FCM;

  static xmpp.RosterManager rosterManager;
  static xmpp.PresenceManager presenceManager;
  static xmpp.MessageHandler messageHandler;
  static xmpp.MessageArchiveManager messageArchiveManager;
  static xmpp.HttpFileUploadManager fileUploadManager;
  static StreamManagementModule streamManagement;

  static xmpp.Connection connection;

  static StreamController<xmpp.XmppConnectionState> connectionStreamController = StreamController();
  static Stream connectionStream = connectionStreamController.stream.asBroadcastStream();

  static StreamController<xmpp.Message> messagesStreamController = StreamController();
  static Stream<xmpp.Message> messagesStream = messagesStreamController.stream.asBroadcastStream();

  static bool loggedIn = false;
  static UserChatModel curUser;
  static List<ContactChatModel> contactsList;

  static healthcheck() {
    healthCheckTimer = Timer.periodic(Duration(seconds: 3), (Timer t) async {
      final reconnectionManagerExists = connection?.reconnectionManager;
      final bool reconnectionManagerActive =
          reconnectionManagerExists != null &&
                  reconnectionManagerExists.isActive
              ? true
              : false;
      final connectionState = connection?.state;

      Log.i(
          TAG,
          '${t.tick} instance: ${instanceKey}, ' +
              'acc:${restoreAccount?.username}, ' +
              'cstate:$connectionState, ' +
              'rmanger:$reconnectionManagerActive');
      // Если менеджер закончил переподключаться,
      // надо дропать имеющееся, оно уже не переподключиться,
      // из-за таймаута сессии на сервере
      // надо новое соединение делать
      if (curUser != null &&
          connection != null &&
          !connection.isOpened() &&
          connection.reconnectionManager != null &&
          !connection.reconnectionManager.isActive) {
        restoreAccount = connection.account;
        //Log.i(TAG, 'DROP CONNECTION');
        JabberConn.clear();
      }

      if (restoreAccount != null &&
          !reconnectionManagerActive &&
          (connectionState == xmpp.XmppConnectionState.ForcefullyClosed ||
              connectionState == xmpp.XmppConnectionState.Closed)) {
        //Log.i(TAG, 'RESTORE CONNECTION WITH ACCOUNT $restoreAccount');
        JabberConn.createConnection(restoreAccount);
      }
    });
  }

  static xmpp.Connection createConnection(
      final xmpp.XmppAccountSettings account) {
    if (connection == null ||
        connection.account.fullJid != account.fullJid ||
        !loggedIn) {
      JabberConn.clear();
      connection = xmpp.Connection.getInstance(account);
      ConnectionListener(connection);
      connection.connect();
      //Log.i(TAG, 'new_connection');
    } else {
      //Log.i(TAG, 'old_connection');
    }
    return connection;
  }

  static xmpp.Connection conn() {
    Map<String, xmpp.Connection> connections = xmpp.Connection.instances;
    if (connections.isEmpty) {
      return null;
    }
    String login = connections.keys.first;
    xmpp.Connection conn = connections[login];

    return conn;
  }

  /* Отправка токена на сервер */
  static Future<bool> sendToken() async {
    if (JabberConn.curUser == null ||
        JabberConn.TOKEN_FCM == null ||
        !JabberConn.loggedIn) {
      Log.d(JabberConn.TAG, 'Not enough data for send token to server');
      return false;
    }
    final queryParameters = {
      'action': 'update_token',
      'phone': JabberConn.curUser.login,
      'token': JabberConn.TOKEN_FCM,
    };
    final uri = Uri.https(JABBER_SERVER, JABBER_REG_ENDPOINT, queryParameters);
    Log.d(JabberConn.TAG, 'query: ${uri.toString()}');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  /* Очистить соединения */
  static void clear() {
    contactsList = null;
    curUser = null;
    loggedIn = false;
    receiver = null;

    rosterManager = null;
    presenceManager = null;
    messageHandler = null;
    messageArchiveManager = null;
    fileUploadManager = null;
    streamManagement = null;

    if (connection != null) {
      connection.close();
      connection = null;
    }
/*
    if (connectionStreamController != null) {
      if (connectionStreamController.sink != null) {
        connectionStreamController.sink.close();
      }
      connectionStreamController.close();
    }
    if (messagesStreamController != null) {
      if (messagesStreamController.sink != null) {
        messagesStreamController.sink.close();
      }
      messagesStreamController.close();
    }
 */

    xmpp.RosterManager.instances.clear();
    xmpp.PresenceManager.instances.clear();
    xmpp.MessageHandler.instances.clear();
    xmpp.MessageArchiveManager.instances.clear();
    xmpp.HttpFileUploadManager.instances.clear();

    xmpp.Connection.instances.clear();
  }

  void dispose() {
    if (connectionStreamController != null) {
      connectionStreamController.close();
    }
    if (messagesStreamController != null) {
      messagesStreamController.close();
    }
  }

}

class ConnectionListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;

  ConnectionListener(xmpp.Connection connection) {
    _connection = connection;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state != xmpp.XmppConnectionState.Closed &&
        state != xmpp.XmppConnectionState.Closing) {
      JabberConn.connectionStreamController.add(state);
    }
    if (_connection.isOpened()) {
      if (state == xmpp.XmppConnectionState.Ready) {
        // чтобы все знали, что надо обновиться, т/к соединение новое
        JabberConn.instanceKey += 1;

        JabberConn.rosterManager = xmpp.RosterManager.getInstance(_connection);
        JabberConn.presenceManager =
            xmpp.PresenceManager.getInstance(_connection);
        JabberConn.messageHandler =
            xmpp.MessageHandler.getInstance(_connection);
        JabberConn.messageArchiveManager =
            xmpp.MessageArchiveManager.getInstance(_connection);
        JabberConn.fileUploadManager =
            xmpp.HttpFileUploadManager.getInstance(_connection);
        JabberConn.streamManagement =
            StreamManagementModule.getInstance(_connection);
        JabberConn.messageHandler.messagesStream
            .listen((xmpp.MessageStanza message) {
          xmpp.Message curMessage = xmpp.Message.fromStanza(message);
          JabberConn.messagesStreamController.add(curMessage);
        });
        JabberConn.connection.reconnectionManager.counter = 0;
        // Пока гасим реконнект
        //JabberConn.connection.reconnectionManager.isActive = true;
        // Получаем инфу по загрузке файлов
        if (JabberConn.fileUploadManager.formType == null) {
          JabberConn.fileUploadManager.queryUploadInfo();
        }
      }
    }
  }
}

