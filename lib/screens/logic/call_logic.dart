import 'dart:async';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:sip_ua/sip_ua.dart';

class CallScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CallScreenLogic';
  SipConnection sipConnection;
  String inCallTime = '00:00';
  Timer _timer;
  Call currentCall;
  UserHistoryModel historyRow;
  Phones curPhone;

  List<CallStateEnum> inCallStates = [
    CallStateEnum.STREAM,
    CallStateEnum.UNMUTED,
    CallStateEnum.MUTED,
    CallStateEnum.CONNECTING,
    CallStateEnum.PROGRESS,
    CallStateEnum.ACCEPTED,
    CallStateEnum.CONFIRMED,
    CallStateEnum.HOLD,
    CallStateEnum.UNHOLD,
    CallStateEnum.CALL_INITIATION,
  ];

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
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
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
    }
  }

  @override
  String getTAG() {
    return TAG;
  }

  @override
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser != null) {
      return;
    }
    bool inCallState = false;
    if (sipConnection != null) {
      inCallState = sipConnection.call != null &&
          inCallStates.contains(sipConnection.call.state);
      if (!inCallState && _timer != null) {
        callEnded(_timer.tick);
        _timer.cancel();
      } else if (inCallState && !_timer.isActive) {
        _startTimer();
      }
    }
    setStateCallback({'inCallState': inCallState});
  }

  Future<void> checkUserReg() async {
    if (JabberConn.curUser == null) {
      sipConnection = null;
      setStateCallback({'curUserExists': false});
      return;
    } else if (JabberConn.curUser != null) {
      createSipConnection(JabberConn.curUser.login);
      setStateCallback({'curUserExists': true});
    }
  }

  Future<void> _startTimer() async {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      Duration duration = Duration(seconds: timer.tick);
      inCallTime = [duration.inMinutes, duration.inSeconds]
          .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
          .join(':');
      setStateCallback({'inCallTime': inCallTime});
    });
  }

  void makeCall(String phoneNumber) {

    String digits = phoneNumber.replaceAll(RegExp('[^0-9]+'), '');
    sipConnection.handleCall(digits);

    setStateCallback({
      'inCallState': true,
      'inCallTime': '00:00',
    });
    _startTimer();
    // Записываем в историю
    call2History(digits);
  }

  void hangup() {
    if (sipConnection != null) {
      sipConnection.handleHangup();
      setStateCallback({'inCallState': false});
    }
    if (_timer != null) {
      callEnded(_timer.tick);
      _timer.cancel();
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

  void call2History(String dest) {
    currentCall = sipConnection.call;
    historyRow = UserHistoryModel(
      login: JabberConn.curUser.login,
      time: DateTime.now().toIso8601String(),
      dest: dest,
      action: 'outgoing_call',
    );
    historyRow.insert2Db();
  }

  Future<void> callEnded(int duration) async {
    if (historyRow == null || historyRow.id == null) {
      return;
    }
    historyRow.updatePartial(historyRow.id, {
      'duration': duration,
    });
    historyRow = null;
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
    if (result.length == 10) {
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
        curPhone = arguments['curPhone'];
        if (curPhone != null) {
          String phoneNumber = preparePhone(curPhone);
          Log.d(TAG, 'phoneNumber $phoneNumber');
          setStateCallback({
            'phoneNumber': phoneNumber,
          });
        }
      }
    });
  }
}
