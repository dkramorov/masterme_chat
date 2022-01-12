import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/core/root_wizard_screen.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:masterme_chat/services/telegram_bot.dart';
import 'package:rxdart/subjects.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

import 'call_keeper.dart';

/*
Доки:
https://firebase.google.com/docs/cloud-messaging/auth-server
https://firebase.google.com/docs/cloud-messaging/xmpp-server-ref

Можно зазырить
https://github.com/adamvduke/mod_interact ?

https://github.com/dverdugo85/mod_fcm/blob/master/mod_fcm.erl

https://github.com/sumaninster/ejabberd_offline_message/blob/master/mod_http_offline.erl
https://github.com/jitendrapathak/ejabberd_push_toffline_users/blob/master/mod_ejabberd_offline_push_old.erl
https://github.com/mrDoctorWho/ejabberd_mod_gcm/blob/master/src/mod_gcm.erl
https://github.com/mrDoctorWho/ejabberd_mod_apns/blob/master/src/mod_apns.erl
https://github.com/proger/mod_pushoff - на 18
https://github.com/devsofpixel7/mod_offline_push/blob/master/src/mod_offline_push.erl на 18
https://github.com/dverdugo85/pushoff/tree/master/mod_pushoff/src - на 19
https://github.com/dverdugo85/push_off/blob/master/mod_pushoff/src/mod_pushoff.erl на 19

https://github.com/kevb/mod_zeropush/blob/master/src/mod_zeropush.erl
https://github.com/nobreak/mod_onesignal/blob/master/src/mod_onesignal.erl

Можно адаптировать пуши
https://github.com/pankajsoni19/fcm-erlang самостоятельный сервер, надо переделать под ejabberd (v1 поддержка)
https://github.com/e4q/epns библиотечка - надо самостоятельно впиндюривать
*/

/* Local Notifications */
class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

/* Remote Notifications */
Future<Map<String, dynamic>> onBackgroundMessageHandler(
    Map<String, dynamic> message) async {
  //await Firebase.initializeApp(); // Вызывает ошибку

  Log.w('onBackgroundMessageHandler', '${message.toString()}');
  String jabaAcc = '';
  if (JabberConn.curUser != null) {
    jabaAcc = JabberConn.curUser.login;
  }
  String sipAcc = '';
  if (SipConnection.userAgent != null) {
    sipAcc = SipConnection.userAgent;
  }
  TelegramBot().notificationResponse('onBackgroundMessageHandler ${message.toString()}' +
      ', for account $jabaAcc, with sip $sipAcc');

  Map<String, dynamic> parsedMsg = PushNotificationsManager.parseIncomingPushNotification(message);
  if (parsedMsg['action'] == 'call') {

  }
  return message;

}

/* Local Notifications */
Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  Log.d(PushNotificationsManager.TAG,
      '=====================$id, $title, $body $payload}');
}

class PushNotificationsManager {
  static const TAG = 'PushNotificationsManager';
  // Для получения ссылки на контекст
  // MaterialApp(navigatorKey: PushNotificationsManager.materialKey, ... // GlobalKey()
  // чтобы получить контекст PushNotificationsManager.materialKey.currentContext
  static final materialKey = GlobalKey<NavigatorState>();

  PushNotificationsManager._();
  factory PushNotificationsManager() => _instance;
  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  String token;

  FirebaseMessaging _firebaseMessaging;
  bool _initialized = false;

  /* Local notifications */
  static const channelId = 'masterme.ru/mastermeNotificationsChannel';
  static const channelName = 'ChatChannel';
  static const channelDesc = 'Chat channel for messages';
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    channelDesc,
    importance: Importance.max,
  );

  static const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDesc,
    importance: Importance.max,
    priority: Priority.max,
  );

  static final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  final MethodChannel platform =
      MethodChannel('masterme.ru/mastermeNotificationsChannel');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings(
      '@drawable/app_icon',
    ),
    iOS: IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    ),
  );
  String selectedNotificationPayload;

  void dispose() {
    didReceiveLocalNotificationSubject.close();
  }

  // Приходит сообщение, значит, надо распарсить
  static Map<String, dynamic> parseIncomingPushNotification(
      Map<String, dynamic> message) {
    Map<String, dynamic> result = {};
    Log.d(TAG, 'parseIncomingPushNotification ${message.toString()}');
    // APNS has strange format
    var aps = message['aps'];
    if (aps != null) {
      final alert = aps['alert'];
      if (alert != null) {
        result['title'] = aps['alert']['title'];
        result['body'] = aps['alert']['body'];
      }
      result['sender'] = message['sender'];
      result['receiver'] = message['receiver'];
      result['action'] = message['action'];
    } else {
      Map<dynamic, dynamic> notification = message['notification'];
      if (notification != null) {
        result['title'] = notification['title'];
        result['body'] = notification['body'];
      }
      var data = message['data'];
      result['sender'] = message['sender'];
      result['receiver'] = message['receiver'];
      result['action'] = message['action'];
      if (data != null) {
        result['sender'] = data['sender'];
        result['receiver'] = data['receiver'];
        result['action'] = data['action'];
      }
    }

    // TODO: collapse {body: aaa, title: test, e: 1, tag: campaign_collapse_key_3739}}
    if (result['sender'] == null || result['receiver'] == null) {
      Log.d(TAG,
          'Ignore notification because sender and receiver is null in ${message.toString()}');
      result['sender'] = 'Test';
      result['receiver'] = 'ALL';
    }
    result['resultText'] = result['sender'] + '=>' + result['receiver'];
    return result;
  }

  /* Отправляем локальный пуш на событие серверного пуша */
  static Future<void> showNotificationOnEvent(Map<String, dynamic> message,
      {bool foreground = false}) async {
    Map<String, dynamic> parsedMsg = parseIncomingPushNotification(message);

    if (parsedMsg['action'] == 'call') {
      return;
    }

    if (foreground &&
        JabberConn.receiver != null &&
        JabberConn.receiver.contains(parsedMsg['sender'])) {
      Log.d(TAG, 'already foreground chat ${parsedMsg.toString()}');
      return;
    }
    PushNotificationsManager.showNotification(
        parsedMsg['title'], parsedMsg['body'], parsedMsg['resultText']);
  }

  Future<void> init() async {
    await Firebase.initializeApp();
    if (!_initialized) {
      _firebaseMessaging = FirebaseMessaging();

      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          Log.i('_firebaseMessaging', 'onMessage: $message');
          showNotificationOnEvent(message, foreground: true);
        },
        onLaunch: (Map<String, dynamic> message) async {
          Log.i('_firebaseMessaging', 'onLaunch: $message');
          showNotificationOnEvent(message);
        },
        /* На йось приходит в onResume, если экран не заблокирован,
           а приложение свернуто
        */
        onResume: (Map<String, dynamic> message) async {
          Log.i('_firebaseMessaging', 'onResume: $message');
          showNotificationOnEvent(message);
          if (Platform.isIOS) {
            onBackgroundMessageHandler(message);
          }
        },
        onBackgroundMessage: Platform.isIOS ? null : onBackgroundMessageHandler,
      );
      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(
              sound: true, badge: true, alert: true, provisional: true));
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        Log.d(TAG, 'Settings registered: $settings');
      });
      _firebaseMessaging.getToken().then((String token) {
        assert(token != null);
        this.token = token;
        JabberConn.TOKEN_FCM = token;
        Log.d(TAG, 'token => $token');
      }).onError((err, trace) {
        TelegramBot().sendError(err.toString());
        TelegramBot().sendError(trace.toString());
      });

      _firebaseMessaging.onTokenRefresh.listen((String newToken) {
        this.token = newToken;
        JabberConn.TOKEN_FCM = token;
      });

      localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      localNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String payload) async {
        if (payload != null) {
          Log.d(TAG, 'notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });

      // Когда жмакаем на push уведомление
      selectNotificationSubject.stream.listen((String payload) async {
        if (materialKey == null) {
          return;
        }

        // Если мы уже на страничке чата
        if (JabberConn.receiver != null &&
            JabberConn.receiver.contains(payload.split('=>')[1])) {
          return;
        }
        // Толкаем на главную
        Navigator.of(materialKey.currentContext)
            .popUntil((route) => route.settings.name == RootScreen.id);
        JabberConn.pushStreamController.add(payload);
      });

      _initialized = true;
    }
  }

  /*
  Показываем пушь уведомление
  TODO: отменять - в badge ложить количество
  await flutterLocalNotificationsPlugin.cancel(NOTIFICATION_ID);
  await flutterLocalNotificationsPlugin.cancelAll();
   */
  static Future<void> showNotification(
      String title, String body, String payload) async {
    if (localNotificationsPlugin == null) {
      Log.e(TAG, 'push notifications not initialized');
      return;
    }
    await localNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: payload);
  }
}
