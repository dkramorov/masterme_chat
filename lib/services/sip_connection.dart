import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:masterme_chat/constants.dart';

class SipConnection implements SipUaHelperListener {
  static const String TAG = 'SipConnection';

  SIPUAHelper helper;
  String userAgent;
  RegistrationState registerState;
  Call call;

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

  SipConnection(String userAgent) {
    if (helper != null && userAgent != userAgent) {
      helper.unregister();
      helper.stop();
      helper = null;
    }
    if (helper == null) {
      helper = SIPUAHelper();
      registerState = helper.registerState;
      helper.addSipUaHelperListener(this);

      UaSettings settings = UaSettings();

      settings.webSocketUrl = SIP_WSS;
      settings.webSocketSettings.extraHeaders = {};

      settings.authorizationUser = SIP_USER;
      settings.password = SIP_PASSWD;
      settings.displayName = SIP_USER;
      settings.uri = '$SIP_USER@$SIP_SERVER';
      settings.userAgent = '${userAgent}_$JABBER_SERVER';
      this.userAgent = userAgent;
      settings.dtmfMode = DtmfMode.RFC2833;

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
        this.call = call;
        break;
      case CallStateEnum.UNMUTED:
      case CallStateEnum.MUTED:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.ACCEPTED:
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
      event.stream?.getAudioTracks()?.first?.enableSpeakerphone(false);
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

  void handleHangup() {
    if (call != null) {
      try {
        call.hangup();
      } catch (ex) {
        Log.e(TAG, ex.toString());
      }
    }
    call = null;
    timer.cancel();
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
/*
    print("______________${registrationState.state}");
    if (registrationState.state == RegistrationStateEnum.REGISTERED) {
      _helper.call('sip:83952959223@calls.223-223.ru', false); // падает, если с видео
    }
 */
  }

  @override
  void transportStateChanged(TransportState state) {
  }
}
