import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:rxdart/subjects.dart';

import 'package:masterme_chat/services/jabber_connection.dart';

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

/* Local Notifications */
Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  Log.d(LocalPushNotificationsManager.TAG,
      '=====================$id, $title, $body $payload}');
}

class LocalPushNotificationsManager {
  static final TAG = 'LocalPushNotificationsManager';

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
    showNotification(
        title, body, '$sender=>$receiver');
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
