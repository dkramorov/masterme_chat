import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:masterme_chat/services/telegram_bot.dart';
import 'package:masterme_chat/constants.dart';

import 'package:http/http.dart' as http;

class CallScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CallScreenLogic';

  static UserHistoryModel historyRow;
  Orgs curCompany;
  ContactChatModel curContact;
  bool isSip = false;
  bool startCall = false; // Сразу начать звонок
  // Количество секунд, которое мы не будем менять inCallState
  int makeCallPressedDelay = 6;
  static int makeCallPressed = -1;

  static final List<List<Map<String, String>>> numPadLabels = [
    [
      {'1': ''},
      {'2': 'abc'},
      {'3': 'def'}
    ],
    [
      {'4': 'ghi'},
      {'5': 'jkl'},
      {'6': 'mno'}
    ],
    [
      {'7': 'pqrs'},
      {'8': 'tuv'},
      {'9': 'wxyz'}
    ],
    [
      {'*': ''},
      {'0': '+'},
      {'#': ''}
    ],
  ];

  CallScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    if (this.setStateCallback == null) {
      this.setStateCallback = (Map<String, dynamic> state) {
        Log.w(TAG, '--- DUMMY for setStateCallback with params $state ---');
      };
    }

    this.screenTimer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${screenTimer.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  @override
  Future<void> checkState() async {
    print("______checkState call-${SipConnection.call};reg-${SipConnection.isRegistered}");
    if (SipConnection.helper != null) {
      if (makeCallPressed > 0) {
        makeCallPressed -= 1;
      }
      bool inCallState = makeCallPressed > 0 || SipConnection.inCallState;

      if (inCallState) {
        final Map<String, Object> callState = {
          'inCallTime': SipConnection.calcCallTime(SipConnection.inCallTime),
          'inCallPhoneNumber': SipConnection.inCallPhoneNumber,
          'makeCallPressed': makeCallPressed,
        };
        Log.d(TAG, callState.toString());
        setStateCallback(callState);
      } else {
        if (SipConnection.call == null) {
          hangup();
        }
      }
      setStateCallback({
        'inCallState': inCallState,
        'isOverlayVisible': SipConnection.isOverlayVisible,
        'incomingInProgress': SipConnection.isRegistered &&
            SipConnection.callManagerState ==
                CallManagerState.IncomingInProgress,
      });
    }
  }

  /* Отправка уведомления (на каждый чих) */
  Future<void> sendNotification(String phone, String msg) async {
    final uri = Uri.parse('https://$JABBER_SERVER$JABBER_NOTIFY_ENDPOINT');
    var response = await http.post(
      uri,
      headers: {
        // HttpHeaders.authorizationHeader: 'Basic xxxxxxx',
        //'Content-Type': 'image/jpeg',
      },
      body: jsonEncode(<String, String>{
        'body': msg,
        'name': JabberConn.curUser.getName(),
        'toJID': phone.replaceAll(RegExp('[^0-9]+'), ''),
        'fromJID': JabberConn.connection.fullJid.local,
        'credentials': JabberConn.credentialsHash(),
      }),
    );
    Log.i(TAG,
        'notification response ${response.statusCode}, ${response.body.toString()}');
    try {
      var decoded = json.decode(response.body);
      await TelegramBot().notificationResponse(
          'Notification msg: ${response.statusCode}=>${JsonEncoder.withIndent('  ').convert(decoded)}');
    } catch (Exception) {
      await TelegramBot().notificationResponse(
          'Notification msg: ${response.statusCode}=>${response.body.toString()}');
    }
  }

  /* Отправка push-data */
  Future<void> sendCallPush(String phone) async {
    final uri = Uri.parse('https://$JABBER_SERVER$JABBER_NOTIFY_ENDPOINT');
    var response = await http.post(
      uri,
      headers: {
        // HttpHeaders.authorizationHeader: 'Basic xxxxxxx',
        //'Content-Type': 'image/jpeg',
      },
      body: jsonEncode(<String, dynamic>{
        'only_data': true,
        'additional_data': {
          'action': 'call',
        },
        'name': JabberConn.curUser.getName(),
        'toJID': phone.replaceAll(RegExp('[^0-9]+'), ''),
        'fromJID': JabberConn.connection.fullJid.local,
        'credentials': JabberConn.credentialsHash(),
      }),
    );
    Log.i(TAG,
        'notification response ${response.statusCode}, ${response.body.toString()}');
    try {
      var decoded = json.decode(response.body);
      await TelegramBot().notificationResponse(
          'Notification msg: ${response.statusCode}=>${JsonEncoder.withIndent('  ').convert(decoded)}');
    } catch (Exception) {
      await TelegramBot().notificationResponse(
          'Notification msg: ${response.statusCode}=>${response.body.toString()}');
    }
  }

  Future<void> makeCall(String phoneNumber) async {
    makeCallPressed = makeCallPressedDelay; // для задержки смены inCallState

    final SipConnection sip = SipConnection();
    String digits = phoneNumber.replaceAll(RegExp('[^0-9]+'), '');
    String sipNumber = phoneNumber;
    if (isSip) {
      sipNumber = 'sip: $phoneNumber';
    }

    SipConnection.inCallTime = 0;
    setStateCallback({
      'makeCallPressed': makeCallPressed,
      'inCallState': true,
      'inCallTime': SipConnection.calcCallTime(SipConnection.inCallTime),
      'inCallPhoneNumber': sipNumber,
    });

    await sip.handleHangup();

    await sip.init(JabberConn.curUser?.login);
    SipConnection.inCallPhoneNumber = phoneNumber;
    // Записываем в историю
    if (curCompany != null) {
      await call2History(digits, companyId: curCompany.id);
    } else {
      await call2History(digits);
    }

    await SipConnection.playOutgoingSound();
    for (int i=0; i<10; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      if (SipConnection.isRegistered) {
        if (isSip) {
          await sip.handleSipCall(digits);
        } else {
          await sip.handleCall(digits);
        }
        await sendCallPush(digits);
        return;
      }
      print('---[ERROR]--- still not registered');
    }
  }

  Future<void> acceptCall() async {
    /* Принять звонок */
    await SipConnection().acceptCall();
    makeCallPressed = -1;
  }

  void hangup() {
    makeCallPressed = -1;
    SipConnection().handleHangup();
    setStateCallback({'inCallState': false});
  }

  void toggleMute() {
    SipConnection().muteAudio();
    //sipConnection.muteVideo();
    //setStateCallback({'audioMuted': sipConnection.videoMuted});
    setStateCallback({'audioMuted': SipConnection.audioMuted});
  }

  void toggleSpeaker() {
    SipConnection().toggleSpeaker();
    setStateCallback({'speakerOn': SipConnection.speakerOn});
  }

  void sendDTMF(String digit) {
    SipConnection().handleDtmf(digit);
  }

  static Future<void> call2History(String dest, {int companyId}) async {
    CallScreenLogic.historyRow = UserHistoryModel(
      login: JabberConn.curUser.login,
      time: DateTime.now().toIso8601String(),
      dest: dest,
      action: 'outgoing_call',
      companyId: companyId,
    );
    CallScreenLogic.historyRow.insert2Db();
  }

  static Future<void> saveCallTime(int duration) async {
    if (CallScreenLogic.historyRow == null ||
        CallScreenLogic.historyRow.id == null) {
      return;
    }
    CallScreenLogic.historyRow.updatePartial(CallScreenLogic.historyRow.id, {
      'duration': duration,
    });
    CallScreenLogic.historyRow = null;
  }

  String preparePhone(Phones phone) {
    String result = '';
    if (phone.prefix != null && phone.prefix != 0) {
      result += phone.prefix.toString();
    }
    if (phone.digits != null && phone.digits != '') {
      result += phone.digits;
    }
    result = result.replaceAll(RegExp('[^0-9]+'), '');
    if (result.length == 11) {
      // do nothing
    } else if (result.length == 10) {
      result = '8$result';
    } else if (result.length == 6) {
      result = '83952$result';
    } else {
      result = '8';
    }
    if (result.length == 11) {
      return phoneMaskHelper(result);
    }
    return result;
  }

  /* Получение аргументов на вьюхе */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    Future.delayed(Duration.zero, () {
      final arguments = ModalRoute.of(context).settings.arguments as Map;
      if (arguments != null) {
        String phoneNumber;
        Phones curPhone = arguments['curPhone'];
        if (curPhone != null) {
          phoneNumber = preparePhone(curPhone);
          Log.d(TAG, '--- parsedArgument phoneNumber $phoneNumber');
          setStateCallback({
            'phoneNumber': phoneNumber,
          });
        }
        String curPhoneStr = arguments['curPhoneStr'];
        if (curPhoneStr != null) {
          phoneNumber = phoneMaskHelper(curPhoneStr);
          Log.d(TAG, '--- parsedArgument phoneNumberStr $phoneNumber');
          setStateCallback({
            'phoneNumber': phoneNumber,
          });
        }
        curCompany = arguments['curCompany'];
        if (curCompany != null) {
          Log.d(TAG, '--- parsedArgument company $curCompany');
          setStateCallback({
            'company': curCompany,
          });
        }
        curContact = arguments['curContact'];
        if (curContact != null) {
          Log.d(TAG, '--- parsedArgument contact $curContact');
          setStateCallback({
            'contact': curContact,
          });
        }
        isSip = arguments['isSip'];
        if (isSip != null) {
          Log.d(TAG, '--- parsedArgument isSip $isSip');
          setStateCallback({
            'isSip': isSip,
          });
        } else {
          isSip = false;
        }
        String incomingCallFrom = arguments['incomingCallFrom'];
        if (incomingCallFrom != null) {
          Log.d(TAG, '--- parsedArgument incomingCallFrom $incomingCallFrom');
          setStateCallback({
            'incomingCallFrom': incomingCallFrom,
          });
        }
        startCall = arguments['startCall'];
        if (startCall != null && startCall) {
          Log.d(TAG, '--- parsedArgument startCall $startCall');
          setStateCallback({
            'startCall': true,
          });
        }
      }
    });
  }
}
