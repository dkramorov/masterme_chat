import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:rxdart/subjects.dart';

import 'package:masterme_chat/services/jabber_connection.dart';

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
Future<dynamic> onBackgroundMessageHandler(Map<String, dynamic> message) async {
  await Firebase.initializeApp();
  //print('onBackgroundMessageHandler: $message');
  //PushNotificationsManager.showNotificationOnEvent(message);

}

/* Local Notifications */
Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  Log.d(PushNotificationsManager.TAG,
      '=====================$id, $title, $body $payload}');
}

class PushNotificationsManager {
  static final TAG = 'PushNotificationsManager';

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

  /* Отправляем локальный пуш на событие серверного пуша */
  static Future<void> showNotificationOnEvent(Map<String, dynamic> message,
      {bool foreground = false}) async {
    final title = message['notification']['title'];
    final body = message['notification']['body'];
    final data = message['data'];
    String sender = message['sender'];
    String receiver = message['receiver'];
    if (data != null) {
      sender = data['sender'];
      receiver = data['receiver'];
    }
    Log.d(TAG, 'New push $sender ${JabberConn.receiver}');
    if (foreground && sender == JabberConn.receiver) {
      Log.d(TAG, 'already foreground chat with user $receiver');
      return;
    }
    PushNotificationsManager.showNotification(
        title, body, '$sender=>$receiver');
  }

  Future<void> init() async {
    if (!_initialized) {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging();

      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          Log.d('_firebaseMessaging', 'onMessage: $message');
          showNotificationOnEvent(message, foreground: true);
        },
        onLaunch: (Map<String, dynamic> message) async {
          Log.d('_firebaseMessaging', 'onLaunch: $message');
          showNotificationOnEvent(message);
        },
        onResume: (Map<String, dynamic> message) async {
          Log.d('_firebaseMessaging', 'onResume: $message');
          showNotificationOnEvent(message);
        },
        onBackgroundMessage: Platform.isIOS ? null : onBackgroundMessageHandler,
      );

      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(
              sound: true, badge: true, alert: true, provisional: true));
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        print("Settings registered: $settings");
      });
      _firebaseMessaging.getToken().then((String token) {
        assert(token != null);
        this.token = token;
        JabberConn.TOKEN_FCM = token;
      });

      _firebaseMessaging.onTokenRefresh.listen((String newToken) {
        this.token = newToken;
        JabberConn.TOKEN_FCM = token;
      });

      localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      localNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String payload) async {
        if (payload != null) {
          Log.d(TAG, 'notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });

      _initialized = true;
    }

  }

  /*
  Показываем пушь уведомление
  TODO: отменять
  await flutterLocalNotificationsPlugin.cancel(NOTIFICATION_ID);
  await flutterLocalNotificationsPlugin.cancelAll();
   */
  static Future<void> showNotification(
      String title, String body, String payload) async {
    if (localNotificationsPlugin == null) {
      Log.e(TAG, 'push notifications not initialized');
      return;
    }
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await localNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: payload);
  }
}
