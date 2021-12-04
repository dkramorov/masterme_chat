import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:masterme_chat/helpers/log.dart';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';

import 'package:xmpp_stone/src/logger/Log.dart' as xmpp_log;
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';

import 'package:http/http.dart' as http;
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class JabberConn {
  static const String TAG = 'JabberConn';
  static const bool LOG_XMPP = false; // Отладочные сообщения xmpp
  static const LOG_XMPP_LEVEL = xmpp_log.LogLevel.INFO;

  static int instanceKey = 0;
  static Timer healthCheckTimer;
  static xmpp.XmppAccountSettings restoreAccount;

  static String receiver;
  static String TOKEN_FCM;
  static String appVersion;

  static xmpp.VCardManager vCardManager;
  static xmpp.RosterManager rosterManager;
  static xmpp.PresenceManager presenceManager;
  static xmpp.MessageHandler messageHandler;
  static xmpp.MessageArchiveManager messageArchiveManager;
  static xmpp.HttpFileUploadManager fileUploadManager;
  static StreamManagementModule streamManagement;

  static xmpp.Connection connection;

  static StreamController<String> pushStreamController = StreamController();
  static Stream pushStream = pushStreamController.stream.asBroadcastStream();

  static StreamController<xmpp.XmppConnectionState> connectionStreamController =
      StreamController();
  static Stream connectionStream =
      connectionStreamController.stream.asBroadcastStream();

  static StreamController<xmpp.Message> messagesStreamController =
      StreamController();
  static Stream<xmpp.Message> messagesStream =
      messagesStreamController.stream.asBroadcastStream();

  static bool loggedIn = false;
  static UserChatModel curUser;
  static List<ContactChatModel> contactsList = [];

  /* sha256 на логин + пароль
     для различных операций, требующих авторизации
  */
  static String credentialsHash() {
    if (JabberConn.curUser != null) {
      List<int> credentials =
          utf8.encode(JabberConn.curUser.login + JabberConn.curUser.passwd);
      return sha256.convert(credentials).toString();
    }
    return null;
  }

  static healthcheck() {
    healthCheckTimer = Timer.periodic(Duration(seconds: 3), (Timer t) async {
      final reconnectionManagerExists = connection?.reconnectionManager;
      final bool reconnectionManagerActive =
          reconnectionManagerExists != null &&
                  reconnectionManagerExists.isActive
              ? true
              : false;
      final connectionState = connection?.state;

      // Логирование
      if (LOG_XMPP) {
        Log.i(
            TAG,
            '${t.tick} instance: ${instanceKey}, ' +
                'acc:${restoreAccount?.username}, ' +
                'cstate:$connectionState, ' +
                'rmanger:$reconnectionManagerActive');
      }

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

    // Сообщения по отладке xmpp
    xmpp_log.Log.logXmpp = LOG_XMPP;
    xmpp_log.Log.logLevel = LOG_XMPP_LEVEL;

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
    contactsList = [];
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

    xmpp.RosterManager.instances.clear();
    xmpp.PresenceManager.instances.clear();
    xmpp.MessageHandler.instances.clear();
    xmpp.MessageArchiveManager.instances.clear();
    xmpp.HttpFileUploadManager.instances.clear();

    xmpp.Connection.instances.clear();
  }

  /* Ищем пользователя в JabberConn.contactsList */
  static ContactChatModel searchInContactsList(ContactChatModel contact) {
    for (ContactChatModel itemInContactsList in JabberConn.contactsList) {
      if (itemInContactsList.login == contact.login) {
        return itemInContactsList;
      }
    }
    return null;
  }

  void dispose() {
    if (pushStreamController != null) {
      pushStreamController.close();
    }
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

  /* TODO: Обрабатываем пуш сообщение,
     добавляем контакт в список если такого контакта нет,
     чтобы отобразить его в ростере
  */
  static void checkContactInRosterFromPush(Map<String, dynamic> message) {
    print('checkContactInRosterFromPush: $message');
  }

  /* Обрабатываем входящее сообщение,
     добавляем контакт в список если такого контакта нет,
     чтобы отобразить его в ростере
  */
  static Future<void> checkContactInRoster(xmpp.Message curMessage) async {
    // Ошибку не обрабатываем
    if (curMessage.type == xmpp.MessageStanzaType.ERROR) {
      return null;
    }
    xmpp.Buddy buddy;
    String friend;
    final String me = JabberConn.connection?.fullJid?.userAtDomain;
    ContactChatModel contact; // Кого обновляем в ростер его
    // Находим себя
    if (me == null) {
      Log.e('[ERROR]: checkContactInRoster', 'me is null');
      return;
    }
    // Находим собеседника
    if (curMessage.from.userAtDomain == me) {
      friend = curMessage.to.userAtDomain;
    } else if (curMessage.to.userAtDomain == me) {
      friend = curMessage.from.userAtDomain;
    }
    if (friend == null) {
      Log.e('[ERROR]: checkContactInRoster', 'friend not found');
      return;
    }
    // Проверяем, что собеседник в контактах
    for (ContactChatModel itemInContactsList in JabberConn.contactsList) {
      if (itemInContactsList.buddy.jid.userAtDomain == friend) {
        contact = itemInContactsList;
      }
    }
    String msgText = '';
    if (curMessage.urlType == null) {
      msgText = curMessage.text;
    } else if (curMessage.urlType == 'file') {
      msgText = 'Отправлен файл';
    } else if (curMessage.urlType == 'image') {
      msgText = 'Отправлено изображение';
    } else if (curMessage.urlType == 'video') {
      msgText = 'Отправлен видео-файл';
    } else if (curMessage.urlType == 'audio') {
      msgText = 'Отправлен аудио-файл';
    }
    // Создаем или обновляем собеседника
    if (contact == null) {
      // Отправить запрос на добавление в ростер
      var newUserJid = xmpp.Jid.fromFullJid(curMessage.from.userAtDomain);
      buddy = xmpp.Buddy(newUserJid);
      JabberConn.rosterManager.addRosterItem(buddy);

      contact = ContactChatModel(
        name: curMessage.from.local,
        login: curMessage.from.userAtDomain,
        parent: me,
        time: curMessage.time.toIso8601String(),
        msg: msgText,
      );
      JabberConn.contactsList.add(contact);
    } else {
      contact.time = curMessage.time.toIso8601String();
      contact.msg = msgText;
      buddy = contact.buddy;
    }
    // Заставлем rosterManager выплюнуть событие с пользователем
    await contact.insert2Db();
    JabberConn.rosterManager.produceNewUser(buddy);
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

        JabberConn.loggedIn = true;

        JabberConn.vCardManager = xmpp.VCardManager.getInstance(_connection);
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

          if (curMessage.from.local == JabberConn.curUser.login &&
              curMessage.to.local == JabberConn.curUser.login) {
            Log.d(JabberConn.TAG,
                'received message from self to self, ignoring...');
            return;
          }
          // Если это MAM тогда не надо checkContactInRoster
          if (curMessage.isMam) {
            // IT'S MAM message, do not need bustling
          } else {
            checkContactInRoster(curMessage);
          }
          JabberConn.messagesStreamController.add(curMessage);
        });
        JabberConn.connection.reconnectionManager.counter = 0;
        // Пока гасим реконнект
        //JabberConn.connection.reconnectionManager.isActive = true;
        // Получаем инфу по загрузке файлов
        if (JabberConn.fileUploadManager.formType == null) {
          JabberConn.fileUploadManager.queryUploadInfo();
        }

        JabberConn.vCardManager.getSelfVCard().then((vCard) {
          if (vCard != null && JabberConn.curUser != null) {
            Future.delayed(Duration(seconds: 1), () async {
              JabberConn.curUser.updateFromVCard(vCard);
            });
          } else {
            Log.d(JabberConn.TAG, 'Your vCard is null');
          }
        });
      }
    }
  }
}
