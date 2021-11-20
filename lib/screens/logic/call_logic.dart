import 'dart:async';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:sip_ua/sip_ua.dart';

class CallScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CallScreenLogic';

  SipConnection sipConnection;
  Call currentCall;
  static UserHistoryModel historyRow;
  Orgs curCompany;

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
    this.screenTimer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${screenTimer.tick}');
    });
  }

  // Добавить подключение если еще нету
  void createSipConnection(String userAgent) {
    if (sipConnection == null) {
      Log.d(TAG, 'new sipConnection with userAgent $userAgent');
      sipConnection = SipConnection();
      sipConnection.init(userAgent);
      setStateCallback({
        'curUserExists': true,
      });
    }
  }

  @override
  String getTAG() {
    return TAG;
  }

  @override
  Future<void> checkState() async {
    if (sipConnection != null && sipConnection.inCallState) {
      Duration duration = Duration(seconds: sipConnection.inCallTime);
      String inCallTime = [duration.inMinutes, duration.inSeconds]
          .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
          .join(':');
      setStateCallback({
        'inCallState': sipConnection.inCallState,
        'inCallTime': inCallTime,
        'inCallPhoneNumber': sipConnection.inCallPhoneNumber,
      });
    }
  }

  Future<void> checkUserReg() async {
    if (JabberConn.curUser == null) {
      sipConnection = null;
      setStateCallback({'curUserExists': false});
      return;
    } else if (JabberConn.curUser != null) {
      createSipConnection(JabberConn.curUser.login);
    }
  }

  void makeCall(String phoneNumber) {
    String digits = phoneNumber.replaceAll(RegExp('[^0-9]+'), '');
    sipConnection.handleCall(digits);
    sipConnection.inCallPhoneNumber = phoneNumber;
    setStateCallback({
      'inCallState': true,
      'inCallTime': '00:00',
      'inCallPhoneNumber': phoneNumber,
    });

    // Записываем в историю
    if (curCompany != null) {
      call2History(digits, companyId: curCompany.id);
    } else {
      call2History(digits);
    }
  }

  void hangup() {
    if (sipConnection != null) {
      sipConnection.handleHangup();
      setStateCallback({'inCallState': false});
    }
  }

  void toggleMute() {
    if (sipConnection != null) {
      sipConnection.muteAudio();
      //sipConnection.muteVideo();
      //setStateCallback({'audioMuted': sipConnection.videoMuted});
      setStateCallback({'audioMuted': sipConnection.audioMuted});
    }
  }

  void toggleSpeaker() {
    if (sipConnection != null) {
      sipConnection.toggleSpeaker();
      setStateCallback({'speakerOn': sipConnection.speakerOn});
    }
  }

  void sendDTMF(String digit) {
    if (sipConnection != null) {
      sipConnection.handleDtmf(digit);
    }
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

  static Future<void> callEnded(int duration) async {
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
      }
    });
  }
}
