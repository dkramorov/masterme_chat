import 'dart:async';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:sip_ua/sip_ua.dart';

class CallScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CallScreenLogic';
  SipConnection sipConnection;
  UserChatModel curUser;
  String inCallTime = '00:00';
  Timer _timer;

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

  // Добавить подключение если еще нету
  void createSipConnection(String userAgent) {
    if (sipConnection == null) {
      Log.d(TAG, 'new sipConnection with userAgent $userAgent');
      sipConnection = SipConnection(userAgent);
    }
  }

  CallScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  @override
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser == curUser) {
      return;
    }
    bool inCallState = false;
    if (sipConnection != null) {
      inCallState = sipConnection.call != null &&
          inCallStates.contains(sipConnection.call.state);
      if (!inCallState && _timer != null) {
        _timer.cancel();
      }
    }
    setStateCallback({'inCallState': inCallState});
  }

  Future<void> checkUserReg() async {
    UserChatModel userFromDb = await UserChatModel.getLastLoginUser();
    if (userFromDb == null && curUser == null) {
      sipConnection = null;
      setStateCallback({'curUserExists': false});
      return;
    } else if (userFromDb == null && curUser != null) {
      createSipConnection(userFromDb.login);
      curUser = userFromDb;
      setStateCallback({'curUserExists': true});
    } else if (userFromDb != null && curUser == null) {
      createSipConnection(userFromDb.login);
      curUser = userFromDb;
      setStateCallback({'curUserExists': true});
    } else if (userFromDb != null && curUser != null) {
      createSipConnection(userFromDb.login);
      if (userFromDb.id != curUser.id) {
        curUser = userFromDb;
        setStateCallback({'curUserExists': true});
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      Duration duration = Duration(seconds: timer.tick);
      inCallTime = [duration.inMinutes, duration.inSeconds]
          .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
          .join(':');
      setStateCallback({'inCallTime': inCallTime});
    });
  }

  void makeCall(String phoneNumber) {
    if (_timer != null) {
      _timer.cancel();
    }
    sipConnection.handleCall(phoneNumber);
    setStateCallback({'inCallState': true, 'inCallTime': '00:00'});
    _startTimer();
  }

  void hangup() {
    if (sipConnection != null) {
      sipConnection.handleHangup();
      setStateCallback({'inCallState': false});
    }
    if (_timer != null) {
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

}
