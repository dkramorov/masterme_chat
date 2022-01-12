/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:callkeep/callkeep.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:uuid/uuid.dart';
import 'jabber_connection.dart';

class FakeCall {
  FakeCall(this.number);
  String number;
  bool holded = false;
  bool muted = false;
}

class CallKeeper {
  static final CallKeeper _singleton = CallKeeper._internal();
  static const TAG = 'CallKeeper';
  SipConnection sip = SipConnection();

  factory CallKeeper() {
    return _singleton;
  }

  CallKeeper._internal();

  static FlutterCallkeep callKeep = FlutterCallkeep();
  bool initialized = false;
  String newUUID() => Uuid().v4();
  Map<String, FakeCall> calls = {};
  static bool askPermsPhoneAccountsOpened = false;

  static Timer sipTimer;
  static int sipTimerCount = 3;

  static void stopSipTimer() {
    if (sipTimer != null) {
      sipTimer.cancel();
    }
    sipTimerCount = 3;
  }

  static String callerUuid;
  static String callerId;
  static String callerName;

  static Future<void> endAllCalls() async {
    if (callKeep != null) {
      await callKeep.endAllCalls();
    }
    stopSipTimer();
  }

  Future<void> handleIncomingCall(Map<String, dynamic> parsedMsg) async {
    Log.d(TAG, 'handleIncomingCall: message => ${parsedMsg.toString()}');
    if (parsedMsg['action'] != 'call') {
      Log.w(TAG, 'It is not call action, ignoring');
    }

    // TODO: 2 звонка
    await endAllCalls();

    callerUuid = newUUID();
    callerId = parsedMsg['sender'];
    callerName = parsedMsg['sender'];

    // SETUP
    await setup();

    Log.d(TAG, 'displayIncomingCall ($callerId)');

    await callKeep.displayIncomingCall(
        callerUuid, callerId, localizedCallerName: callerName,
        hasVideo: false);

    if (JabberConn.curUser == null) {
      Log.d(TAG, 'SIP user is null, breaking call...');
      //await callKeep.endAllCalls();
    } else {
      Log.d(TAG, 'SIP user is NOT null, try display CALL...');
    }

    await callKeep.backToForeground();

    return null;
  }

  Future<void> setup() async {
    print('callKeep initialized $initialized');
    if (!initialized) {
      await callKeep.setup(
          <String, dynamic>{
            'ios': {
              'appName': '8800 help',
            },
            'android': {
              'alertTitle': 'Требуется разрешение',
              'alertDescription':
              'Приложению для принятия звонков нужен доступ к аккаунту телефона на звонки',
              'cancelButton': 'Cancel',
              'okButton': 'ok',
              'foregroundService': {
                'channelId': 'com.company.my',
                'channelName': 'Foreground service for my app',
                'notificationTitle': 'My app is running on background',
                'notificationIcon': 'Path to the resource icon of the notification',
              },
            },
          });

      callKeep.on(CallKeepPerformAnswerCallAction(),
              (CallKeepPerformAnswerCallAction event) {
            stopSipTimer();

            if (callerId == null) {
              Log.w(TAG, '--- callerId is null ---');
              return;
            }
            Log.d(TAG, 'CallKeepPerformAnswerCallAction ${event.callUUID}');
            Timer(const Duration(seconds: 1), () {
              Log.d(TAG,
                  '[setCurrentCallActive] $callerUuid, callerId: $callerId, callerName: $callerName');
              callKeep.setCurrentCallActive(callerUuid);
            });

            sipTimer = Timer.periodic(Duration(seconds:1), (result) {
              print('---- SIP TIMER $sipTimerCount ---');
              sipTimerCount -= 1;
              if (SipConnection.helper != null && SipConnection.helper.registered) {
                stopSipTimer();
              }
              if (sipTimerCount <= 0) {
                stopSipTimer();
              }
              Log.d(TAG, '----callKeeper TIMER=$sipTimerCount,' +
                  ' sip incoming=${SipConnection.incomingInProgress},'
                      ' sip state=${SipConnection.state}---');
              if (SipConnection.incomingInProgress) {
                stopSipTimer();
                sip.acceptCall();
              }
            });
          });

      callKeep.on(CallKeepPerformEndCallAction(),
              (CallKeepPerformEndCallAction event) {
            Log.d(TAG, 'CallKeepPerformEndCallAction ${event.callUUID}');
            stopSipTimer();
            callKeep.endCall(event.callUUID);
            sip.handleHangup();
          });

      initialized = true;
    }
  }


  void removeCall(String callUUID) {
    stopSipTimer();
    calls.remove(callUUID);
  }

  void setCallHold(String callUUID, bool held) {
    calls[callUUID].holded = held;
  }

  void setCallMuted(String callUUID, bool muted) {
    calls[callUUID].muted = muted;
  }

  Future<void> answerCall(CallKeepPerformAnswerCallAction event) async {
    final String callUUID = event.callUUID;
    final String number = calls[callUUID].number;
    print('[answerCall] $callUUID, number: $number');
    Timer(const Duration(seconds: 1), () {
      print('[setCurrentCallActive] $callUUID, number: $number');
      callKeep.setCurrentCallActive(callUUID);
    });
  }

  Future<void> endCall(CallKeepPerformEndCallAction event) async {
    stopSipTimer();
    print('[endCall]: ${event.callUUID}');
    removeCall(event.callUUID);
  }

  Future<void> didPerformDTMFAction(CallKeepDidPerformDTMFAction event) async {
    print('[didPerformDTMFAction] ${event.callUUID}, digits: ${event.digits}');
  }

  Future<void> didReceiveStartCallAction(
      CallKeepDidReceiveStartCallAction event) async {
    if (event.handle == null) {
      print('______________________NULL');
      // @TODO: sometime we receive `didReceiveStartCallAction` with handle` undefined`
      return;
    }
    final String callUUID = event.callUUID ?? newUUID();
    calls[callUUID] = FakeCall(event.handle);
    print('[didReceiveStartCallAction] $callUUID, number: ${event.handle}');

    callKeep.startCall(callUUID, event.handle, event.handle);

    Timer(const Duration(seconds: 1), () {
      print('[setCurrentCallActive] $callUUID, number: ${event.handle}');
      callKeep.setCurrentCallActive(callUUID);
    });
  }

  Future<void> didPerformSetMutedCallAction(
      CallKeepDidPerformSetMutedCallAction event) async {
    final String number = calls[event.callUUID].number;
    print(
        '[didPerformSetMutedCallAction] ${event.callUUID}, number: $number (${event.muted})');
    setCallMuted(event.callUUID, event.muted);
  }

  Future<void> didToggleHoldCallAction(
      CallKeepDidToggleHoldAction event) async {
    final String number = calls[event.callUUID].number;
    print(
        '[didToggleHoldCallAction] ${event.callUUID}, number: $number (${event.hold})');
    setCallHold(event.callUUID, event.hold);
  }

  Future<void> hangup(String callUUID) async {
    stopSipTimer();
    callKeep.endCall(callUUID);
    removeCall(callUUID);
  }

  Future<void> setOnHold(String callUUID, bool held) async {
    callKeep.setOnHold(callUUID, held);
    final String handle = calls[callUUID].number;
    print('[setOnHold: $held] $callUUID, number: $handle');
    setCallHold(callUUID, held);
  }

  Future<void> setMutedCall(String callUUID, bool muted) async {
    callKeep.setMutedCall(callUUID, muted);
    final String handle = calls[callUUID].number;
    print('[setMutedCall: $muted] $callUUID, number: $handle');
    setCallMuted(callUUID, muted);
  }

  Future<void> updateDisplay(String callUUID) async {
    final String number = calls[callUUID].number;
    // Workaround because Android doesn't display well displayName, se we have to switch ...
    if (isIOS) {
      callKeep.updateDisplay(callUUID,
          displayName: 'New Name', handle: number);
    } else {
      callKeep.updateDisplay(callUUID,
          displayName: number, handle: 'New Name');
    }
    print('[updateDisplay: $number] $callUUID');
  }

  Future<void> displayIncomingCallDelayed(String number) async {
    Timer(const Duration(seconds: 3), () {
      displayIncomingCall(number);
    });
  }

  Future<void> displayIncomingCall(String number) async {
    final String callUUID = newUUID();
    calls[callUUID] = FakeCall(number);

    final bool hasPhoneAccount = await callKeep.hasPhoneAccount();

    print('Display incoming call now, hasPhoneAccount: $hasPhoneAccount');
    if (!hasPhoneAccount) {
      // TODO: notification
      print('--- Permission error ---');
    }

    print('[displayIncomingCall] $callUUID number: $number');
    callKeep.displayIncomingCall(callUUID, number,
        handleType: 'number', hasVideo: false);
    callKeep.backToForeground();
  }

  void didDisplayIncomingCall(CallKeepDidDisplayIncomingCall event) {
    var callUUID = event.callUUID;
    var number = event.handle;
    print('[displayIncomingCall] $callUUID number: $number');
    calls[callUUID] = FakeCall(number);
  }

  void onPushKitToken(CallKeepPushKitToken event) {
    print('[onPushKitToken] token => ${event.token}');
  }

  static Future<void> checkPermissions(BuildContext context) async {
    if (askPermsPhoneAccountsOpened) {
      return;
    }
    askPermsPhoneAccountsOpened = true;
    final bool hasPhoneAccount = await callKeep.hasPhoneAccount();

    if (!hasPhoneAccount) {
      callKeep.hasDefaultPhoneAccount(context, <String, dynamic>{
        'alertTitle': 'Требуется разрешение',
        'alertDescription':
        'Требуется разрешение к аккаунту телефона для получения звонков',
        'cancelButton': 'Cancel',
        'okButton': 'ok',
        'foregroundService': {
          'channelId': 'com.company.my',
          'channelName': 'Foreground service for my app',
          'notificationTitle': 'My app is running on background',
          'notificationIcon': 'Path to the resource icon of the notification',
        },
      });
    }

  }

  void initState() {
    callKeep.on(CallKeepDidDisplayIncomingCall(), didDisplayIncomingCall);
    callKeep.on(CallKeepPerformAnswerCallAction(), answerCall);
    callKeep.on(CallKeepDidPerformDTMFAction(), didPerformDTMFAction);
    callKeep.on(
        CallKeepDidReceiveStartCallAction(), didReceiveStartCallAction);
    callKeep.on(CallKeepDidToggleHoldAction(), didToggleHoldCallAction);
    callKeep.on(
        CallKeepDidPerformSetMutedCallAction(), didPerformSetMutedCallAction);
    callKeep.on(CallKeepPerformEndCallAction(), endCall);
    callKeep.on(CallKeepPushKitToken(), onPushKitToken);

    // SETUP
    setup();
  }

}
*/