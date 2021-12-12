import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:masterme_chat/constants.dart';

import 'jabber_connection.dart';


class SipConnection implements SipUaHelperListener {
  static const String TAG = 'SipConnection';
  bool inCallState = false;
  bool incomingInProgress = false;

  static List<CallStateEnum> inCallStates = [
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


  static final SipConnection _singleton = SipConnection._internal();
  factory SipConnection() {
    return _singleton;
  }
  SipConnection._internal();

  SIPUAHelper helper;
  String userAgent;
  RegistrationState registerState;
  Call call;
  String inCallPhoneNumber = ''; // Чтобы подписывать куда звонок идет сейчас
  int inCallTime = 0; // Продолжительность звонка

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  double localVideoHeight;
  double localVideoWidth;
  EdgeInsetsGeometry localVideoMargin;
  MediaStream localStream;
  MediaStream remoteStream;

  String timeLabel = '00:00';
  Timer timer;
  bool audioMuted = false;
  bool videoMuted = false;
  bool speakerOn = false;
  bool hold = false;
  String holdOriginator;
  CallStateEnum state = CallStateEnum.NONE;

  void init(String newUserAgent) {
    if (helper != null) {
      if (userAgent != newUserAgent || !helper.registered) {
        Log.d(TAG, ' --- Set userAgent from $userAgent to $newUserAgent');
        helper.unregister();
        helper.stop();
        helper = null;
      }
    }
    if (helper == null) {
      helper = SIPUAHelper();
      registerState = helper.registerState;
      helper.addSipUaHelperListener(this);

      UaSettings settings = UaSettings();

      settings.webSocketUrl = SIP_WSS;
      settings.webSocketSettings.extraHeaders = {};

      // Пользователь сип по умолчанию
      //settings.authorizationUser = SIP_USER;
      //settings.password = SIP_PASSWD;
      //settings.displayName = SIP_USER;
      //settings.uri = '$SIP_USER@$SIP_SERVER';

      // Текущий джаббер юзер
      settings.authorizationUser = JabberConn.curUser.login;
      settings.password = JabberConn.curUser.passwd;
      settings.displayName = JabberConn.curUser.login;
      settings.uri = '${JabberConn.curUser.login}@$SIP_SERVER';

      settings.userAgent = '${newUserAgent}_$JABBER_SERVER';
      this.userAgent = newUserAgent;
      settings.dtmfMode = DtmfMode.RFC2833;
      settings.iceServers = [{'url': 'stun:91.185.46.56:3478'}];

      helper.start(settings);

      _startTimer();
      _initRenderers();

      helper.addSipUaHelperListener(this);
    }
  }

  void _initRenderers() async {
    if (localRenderer != null) {
      await localRenderer.initialize();
    }
    if (remoteRenderer != null) {
      await remoteRenderer.initialize();
    }
  }

  void _disposeRenderers() {
    if (localRenderer != null) {
      localRenderer.dispose();
      localRenderer = null;
    }
    if (remoteRenderer != null) {
      remoteRenderer.dispose();
      remoteRenderer = null;
    }
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (call != null) {
        // Если мы в звонке
        inCallState = inCallStates.contains(call.state);
        inCallTime += 1;
      } else {
        inCallState = false;
      }
      Duration duration = Duration(seconds: timer.tick);
      timeLabel = [duration.inMinutes, duration.inSeconds]
          .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
          .join(':');
    });
  }

  void toggleSpeaker() {
    if (localStream != null) {
      speakerOn = !speakerOn;
      localStream.getAudioTracks()[0].enableSpeakerphone(speakerOn);
    }
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    state = callState.state;

    if (callState.state == CallStateEnum.CALL_INITIATION) {
      this.call = call;

      if (call.direction == 'INCOMING') {
        incomingInProgress = true;
      }
      inCallTime = 0;
    }

    if (callState.state == CallStateEnum.HOLD ||
        callState.state == CallStateEnum.UNHOLD) {
      hold = callState.state == CallStateEnum.HOLD;
      holdOriginator = callState.originator;
      return;
    }

    if (callState.state == CallStateEnum.MUTED) {
      if (callState.audio) audioMuted = true;
      if (callState.video) videoMuted = true;
      return;
    }

    if (callState.state == CallStateEnum.UNMUTED) {
      if (callState.audio) audioMuted = false;
      if (callState.video) videoMuted = false;
      return;
    }

    if (callState.state != CallStateEnum.STREAM) {
      state = callState.state;
    }

    switch (callState.state) {
      case CallStateEnum.STREAM:
        _handelStreams(callState);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        CallScreenLogic.callEnded(inCallTime);
        inCallState = false;
        incomingInProgress = false;
        break;
      case CallStateEnum.CONNECTING:
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.UNMUTED:
      case CallStateEnum.MUTED:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.NONE:
      case CallStateEnum.CALL_INITIATION:
      case CallStateEnum.REFER:
        break;
    }
  }

  void _handelStreams(CallState event) async {
    MediaStream stream = event.stream;
    if (event.originator == 'local') {
      if (localRenderer != null) {
        localRenderer.srcObject = stream;
      }
      event.stream?.getAudioTracks()?.first?.enableSpeakerphone(speakerOn);
      localStream = stream;
    }
    if (event.originator == 'remote') {
      if (remoteRenderer != null) {
        remoteRenderer.srcObject = stream;
      }
      remoteStream = stream;
    }
  }

  /* Инициация звонка */
  void handleCall(String toPhoneNumber) {
    handleHangup();
    final phone = toPhoneNumber.replaceAll(RegExp('[^0-9]+'), '');
    Log.d(TAG, 'calling to $phone');
    helper.call(phone, false);
  }
  /* Инициация sip звонка */
  void handleSipCall(String toPhoneNumber) {
    handleHangup();
    final phone = toPhoneNumber.replaceAll(RegExp('[^0-9]+'), '');
    Log.d(TAG, 'calling to $phone');
    helper.call('app_$phone', false);
  }

  /* Прием входящего */
  void acceptCall() async {
    incomingInProgress = false;
    if (call == null) {
      Log.e(TAG, 'Already null sipConnection or call');
      return;
    }
    if (call.direction != 'INCOMING') {
      Log.e(TAG, 'It is not incoming call');
      return;
    }
    call.answer(helper.buildCallOptions(true));
  }

  void handleHangup() {
    if (call != null) {
      try {
        call.hangup();
      } catch (ex) {
        Log.e(TAG, ex.toString());
      }
    }
    call = null;
  }

  void handleAccept() {
    call.answer(helper.buildCallOptions());
  }

  void switchCamera() {
    if (localStream != null) {
      Helper.switchCamera(localStream.getVideoTracks()[0]);
    }
  }

  void muteAudio() {
    if (call == null) {
      Log.w(TAG, 'Call is null');
      return;
    }
    if (audioMuted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
  }

  void muteVideo() {
    if (videoMuted) {
      call.unmute(false, true);
    } else {
      call.mute(false, true);
    }
  }

  void handleHold() {
    if (hold) {
      call.unhold();
    } else {
      call.hold();
    }
  }

  void handleDtmf(String tone) {
    if (call != null) {
      call.sendDTMF(tone);
      print('Dtmf tone => $tone');
    } else {
      Log.w(TAG, 'call is null');
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
  }

  @override
  void registrationStateChanged(RegistrationState registrationState) {
    registerState = registrationState;
    Log.w(TAG, ' --- Register state ${registerState.state.toString()}, ${registerState.cause.toString()}');
/*
    if (registrationState.state == RegistrationStateEnum.REGISTERED) {
      _helper.call('sip:83952959223@calls.223-223.ru', false); // падает, если с видео
    }
 */
  }

  @override
  void transportStateChanged(TransportState state) {
  }

}
