import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/core/root_wizard_screen.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:masterme_chat/services/telegram_bot.dart';
import 'package:rxdart/subjects.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

/*
Доки:
https://firebase.google.com/docs/cloud-messaging/auth-server
https://firebase.google.com/docs/cloud-messaging/xmpp-server-ref

Андроид входящий звонок через пушь виджет
https://forasoft.com/blog/article/how-to-make-a-custom-android-call-notification-455
https://jungleworks.com/calling-banner-how-to-make-an-incoming-call-notification-banner-in-android-using-service/

Плагин для андроид
https://medium.com/litslink/flutter-how-to-create-your-own-native-notification-in-android-ba2bd2a5d97
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

Future<void> showIncomingCallNotificationTemplate(
    Map<String, dynamic> parsedMsg) async {
  /* Показываем пушь уведомление о входящем звонке по распарсенному пушу */
  final String senderStr = parsedMsg['sender_str'];
  final String sender = parsedMsg['sender'];
  final String receiver = parsedMsg['receiver'];
  final String name = parsedMsg['name'] != null
      ? 'Звонок от ' + parsedMsg['name']
      : 'Входящий звонок';
  final String payload = 'call_' + sender + '=>' + receiver;
  await PushNotificationsManager.localNotificationsPlugin.show(
    PushNotificationsManager.NOTIFICATION_ID_CALL,
    name,
    senderStr,
    NotificationDetails(
        android: AndroidNotificationDetails(
      PushNotificationsManager.channelId + '3',
      PushNotificationsManager.channelName + '3',
      PushNotificationsManager.channelDesc + '3',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      // Дополнительные опции
      channelShowBadge: true,
      icon: '@mipmap/headset',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/logo'),
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ringtone'),
    )),
    payload: payload,
  );
}

Future<Map<String, dynamic>> onBackgroundMessageHandler(
    Map<String, dynamic> message) async {
  /* Обработчик push сообщения со свернутого (фонового) и выкинутого режима
  */
  //await Firebase.initializeApp(); // Вызывает ошибку

  final String tag = 'onBackgroundMessageHandler';
  Log.w(tag, '${message.toString()}');

  Map<String, dynamic> parsedMsg =
      PushNotificationsManager.parseIncomingPushNotification(message);
  if (parsedMsg['action'] == 'call') {
    Log.i(tag, '$parsedMsg');
    await showIncomingCallNotificationTemplate(parsedMsg);
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
  static const incomingPushMethod = MethodChannel('java/incomingPushMethod');
  static const int NOTIFICATION_ID_CALL = 9;

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
  static const channelKey =
      'com.google.firebase.messaging.default_notification_channel_id';
  static const channelName = 'ChatChannel';
  static const channelDesc = 'Chat channel for messages';

  static final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  final MethodChannel platform = MethodChannel(channelId);
  final InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings(
      '@drawable/app_icon',
    ),
    iOS: IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    ),
  );

  void dispose() {
    didReceiveLocalNotificationSubject.close();
  }

  // Приходит сообщение, значит, надо распарсить
  static Map<String, dynamic> parseIncomingPushNotification(
      Map<String, dynamic> message) {
    Map<String, dynamic> result = {};
    Log.d(TAG, 'parseIncomingPushNotification ${message.toString()}');

    result['sender'] = message['sender'];
    result['receiver'] = message['receiver'];
    result['name'] = message['name'];
    result['action'] = message['action'];

    // APNS has strange format
    var aps = message['aps'];
    if (aps != null) {
      final alert = aps['alert'];
      if (alert != null) {
        result['title'] = aps['alert']['title'];
        result['body'] = aps['alert']['body'];
      }
    } else {
      Map<dynamic, dynamic> notification = message['notification'];
      if (notification != null) {
        result['title'] = notification['title'];
        result['body'] = notification['body'];
      }
      var data = message['data'];
      if (data != null) {
        result['sender'] = data['sender'];
        result['receiver'] = data['receiver'];
        result['name'] = data['name'];
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

    result['sender_str'] = '';
    if (result['sender'] != null && result['sender'].length == 11) {
      result['sender_str'] = phoneMaskHelper(result['sender']);
    }
    return result;
  }

  /* Отправляем локальный пуш на событие серверного пуша */
  static Future<void> showNotificationOnEvent(Map<String, dynamic> message,
      {bool foreground = false}) async {
    Map<String, dynamic> parsedMsg = parseIncomingPushNotification(message);
    print('___________________________________________showNotificationOnEvent');
    // Входящий звонок
    if (parsedMsg['action'] == 'call') {
      if (!foreground) {
        // Показываем пушь на входящий
        await showIncomingCallNotificationTemplate(parsedMsg);
      } else {
        // Отправляем событие о звонке
        final String payload =
            'call_' + parsedMsg['sender'] + '=>' + parsedMsg['receiver'];
        Log.w(TAG, 'payload for pushStream $payload');
        JabberConn.pushStreamController.add(payload);
      }
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
          ?.createNotificationChannel(AndroidNotificationChannel(
            channelId,
            channelName,
            channelDesc,
            importance: Importance.max,
          ));

      localNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String payload) async {
        if (payload != null) {
          Log.d(TAG, 'notification payload: $payload');
        }

        // Не работает нормально с закрытого приложения
        selectNotificationSubject.add(payload);
      });

      // Когда жмакаем-нажимаем на push уведомление
      // С закрытого приложения это не работает
      selectNotificationSubject.stream.listen((String payload) async {
        if (materialKey == null) {
          return;
        }
        Log.i('selectNotificationSubject', 'payload=$payload');
        // Если мы уже на страничке чата
        if (JabberConn.receiver != null &&
            payload.contains('=>') &&
            JabberConn.receiver.contains(payload.split('=>')[1])) {
          return;
        }
        // Толкаем на главную
        Navigator.of(materialKey.currentContext)
            .popUntil((route) => route.settings.name == RootScreen.id);

        // С выкинутого не работает контроллер
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
      String title, String body, String payload,
      {bool fullScreen: false, int notificationId: 0}) async {
    if (localNotificationsPlugin == null) {
      Log.e(TAG, 'push notifications not initialized');
      return;
    }
    if (fullScreen) {
      // Полноэкранный пушь
      await localNotificationsPlugin.show(
          notificationId,
          title,
          body,
          NotificationDetails(
              android: AndroidNotificationDetails(
            channelId + '2',
            channelName + '2',
            channelDesc + '2',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            // Дополнительные опции
            channelShowBadge: true,
            icon: '@mipmap/headset',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/logo'),
            playSound: true,
            sound: RawResourceAndroidNotificationSound('ringtone'),
          )),
          payload: payload);
    } else {
      await localNotificationsPlugin.show(
          0,
          title,
          body,
          NotificationDetails(
              android: AndroidNotificationDetails(
            channelId + '1',
            channelName + '1',
            channelDesc + '1',
            importance: Importance.max,
            priority: Priority.max,
          )),
          payload: payload);
    }
  }

  /* ДЕМОНСТРАЦИОННАЯ ФУНКЦИЯ */
  static Future<void> showNotificationCustomSound() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId + '3',
      channelName + '3',
      channelDesc + '3',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ringtone'),
    );
    const IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails(sound: 'ringtone.aiff');
    const MacOSNotificationDetails macOSPlatformChannelSpecifics =
        MacOSNotificationDetails(sound: 'ringtone.aiff');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: macOSPlatformChannelSpecifics);

    await localNotificationsPlugin.show(
        NOTIFICATION_ID_CALL,
        'custom sound notification title',
        'custom sound notification body',
        platformChannelSpecifics);
  }
}
