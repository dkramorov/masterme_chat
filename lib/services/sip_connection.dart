import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:masterme_chat/constants.dart';

import 'jabber_connection.dart';

enum CallManagerState{
  Idle,
  OutgoingStarted,
  OutgoingInProgress,
  IncomingStarted,
  IncomingInProgress, // Показываем окно с кнопками принять/отклонить звонок
  InCall,
}

class SipConnection implements SipUaHelperListener {
  static const String TAG = 'SipConnection';

  static bool isRegistered = false;
  static bool isOverlayVisible = false;

  static bool inCallState = false;
  static AudioCache audioCache = AudioCache();
  static AudioPlayer audioPlayer;
  static final String outgoingSound = 'call/ringbacktone.wav';
  static final String incomingSound = 'call/ringtone.wav';
  static Timer pendingCall;
  static CallManagerState callManagerState = CallManagerState.Idle;

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

  static SIPUAHelper helper;
  static String userAgent;
  static RegistrationState registerState;
  static Call call;
  static String inCallPhoneNumber = ''; // Чтобы подписывать куда звонок идет сейчас
  static int inCallTime = 0; // Продолжительность звонка

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  double localVideoHeight;
  double localVideoWidth;
  EdgeInsetsGeometry localVideoMargin;
  MediaStream localStream;
  MediaStream remoteStream;

  String timeLabel = '00:00';
  static Timer timer;
  static bool audioMuted = false;
  static bool videoMuted = false;
  static bool speakerOn = false;
  static bool hold = false;
  static String holdOriginator;
  static CallStateEnum state = CallStateEnum.NONE;

  /* Вывод времени в формате 00:00 */
  static String calcCallTime(int callTime) {
    Duration duration = Duration(seconds: callTime);
    String result = [duration.inMinutes, duration.inSeconds]
        .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
        .join(':');
    return result;
  }

  Future<void> init(String newUserAgent) async {
    /* Инициализируем сип соединение, если оно отсутствует */
    /*
    if ((newUserAgent == null) || (newUserAgent == '')) {
      Log.w(TAG, '--- newUserAgent: $newUserAgent');
      return;
    }
    */
    Log.w(TAG, '--- newUserAgent: $newUserAgent');
    /*
    if (helper != null) {
      if (userAgent != newUserAgent || !helper.registered) {
        Log.d(TAG, ' --- Set userAgent from $userAgent to $newUserAgent');
        if (helper.registered) {
          helper.unregister();
        }
        helper.stop();
        helper = null;
      }
    }
    */
    if (!isRegistered) {
      if (helper != null) {
        helper.stop();
      }
      helper = null;
    }
    if (helper == null) {
      UaSettings settings = UaSettings();
      settings.webSocketUrl = SIP_WSS;
      settings.webSocketSettings.extraHeaders = {};

      //settings.webSocketSettings.allowBadCertificate = true;
      // Пользователь сип по умолчанию
      //settings.authorizationUser = SIP_USER;
      //settings.password = SIP_PASSWD;
      //settings.displayName = SIP_USER;
      //settings.uri = '$SIP_USER@$SIP_SERVER';

      String login;
      String passwd;
      // Текущий джаббер юзер или
      // находим логин и пароль по входящему логину
      if (JabberConn.curUser != null) {
        login = JabberConn.curUser.login;
        passwd = JabberConn.curUser.passwd;
      } else {
        final UserChatModel user = await UserChatModel.getByLogin(newUserAgent);
        if (user != null) {
          login = user.login;
          passwd = user.passwd;
        }
      }

      if (login == null || passwd == null) {
        Log.e(TAG, 'login/passwd not found for $newUserAgent');
        return;
      }
      //Log.w(TAG, '--- login/passwd: $login / $passwd');
      settings.authorizationUser = login;
      settings.password = passwd;

      settings.displayName = login;
      settings.uri = '$login@$SIP_SERVER';

      settings.userAgent = '${newUserAgent}_$JABBER_SERVER';
      userAgent = newUserAgent;
      settings.dtmfMode = DtmfMode.RFC2833;

      settings.iceServers = [
        {'url': 'stun:91.185.46.56:3478'}
      ];

      helper = SIPUAHelper();
      helper.start(settings);
      helper.addSipUaHelperListener(SipConnection());

      _startTimer();
      await _initRenderers();
    }
  }

  Future<void> _initRenderers() async {
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
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      print('------$state, ${timer.tick} - $isRegistered');
      inCallState = inCallStates.contains(state);
      if (call != null) {
        // Если мы в звонке
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

  void resetInCallState() {
    /* Сброс различных состояний, которые могли быть выставлены в процессе звонка */
    audioMuted = false;
    videoMuted = false;
    speakerOn = false;
    hold = false;

    inCallState = false;

    call = null;
    stopSound();
  }

  @override
  Future<void> callStateChanged(Call curCall, CallState callState) async {
    state = callState.state;

    if (state == CallStateEnum.CALL_INITIATION) {
      call = curCall;

      if (call.direction == 'INCOMING') {
        if (callManagerState != CallManagerState.IncomingInProgress) {
          callManagerState = CallManagerState.IncomingInProgress;
          Map<String, dynamic> parsedMsg = {
            'action': 'call',
            'sender': call.remote_identity,
            'receiver': call.local_identity,
          };
          Log.d(TAG, 'raise incoming call with $parsedMsg');
          inCallPhoneNumber = phoneMaskHelper(call.remote_identity);
          //showInCallOverlay('call_${call.remote_identity}=>${call.local_identity}');
        } else {
          Log.w(TAG, 'incoming already in progress');
        }
      }

      inCallTime = 0;
    }

    if (state == CallStateEnum.HOLD ||
        state == CallStateEnum.UNHOLD) {
      hold = state == CallStateEnum.HOLD;
      holdOriginator = callState.originator;
      return;
    }

    if (state == CallStateEnum.MUTED) {
      if (callState.audio) audioMuted = true;
      if (callState.video) videoMuted = true;
      return;
    }

    if (state == CallStateEnum.UNMUTED) {
      if (callState.audio) audioMuted = false;
      if (callState.video) videoMuted = false;
      return;
    }

    switch (state) {
      case CallStateEnum.STREAM:
        _handelStreams(callState);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        callManagerState = CallManagerState.Idle;
        CallScreenLogic.makeCallPressed = -1;
        await CallScreenLogic.saveCallTime(inCallTime);
        resetInCallState();
        break;
      case CallStateEnum.CONNECTING:
      case CallStateEnum.UNMUTED:
      case CallStateEnum.MUTED:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.NONE:
      case CallStateEnum.CALL_INITIATION:
      case CallStateEnum.REFER:
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        callManagerState = CallManagerState.InCall;
        CallScreenLogic.makeCallPressed = -1;
        await stopSound();
        break;
    }
    Log.i(TAG, '--------------------------> state is $state, $callManagerState');
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

  static Future<void> stopSound() async {
    /* Затыкаемся с гудками входящими или исходящими */
    if (audioPlayer != null) {
      await audioPlayer.pause();
    }
  }

  static Future<void> playOutgoingSound() async {
    /* Издаем звук исходящего звонка (гудок) */
    audioPlayer = await audioCache.loop(outgoingSound, stayAwake: true);
  }

  static Future<void> playIncomingSound() async {
    /* Издаем звук входящего звонка (гудок)
       TODO: сделать проверку на то, что плеер уже дилинькает
    */
    audioPlayer = await audioCache.loop(incomingSound, stayAwake: true);
  }

  /* call */
  Future<void> handleCall(String phone) async {
    Log.d(TAG, 'calling to $phone');
    await helper.call(phone, true);
  }

  /* SIP call */
  Future<void> handleSipCall(String phone) async {
    Log.d(TAG, 'SIP calling to $phone');
    await helper.call('app_$phone', true);
  }

  /* Прием входящего */
  Future<void> acceptCall() async {
    final SipConnection sip = SipConnection();
    await SipConnection.stopSound();
    callManagerState = CallManagerState.IncomingInProgress;

    if (!SipConnection.isRegistered) {
      Log.w(TAG, 'Try register sip for ${JabberConn.curUser?.login}');
      await sip.init(JabberConn.curUser?.login);
    }
    for (int i=0; i<10; i++) {
      if (call != null && isRegistered) {
        break;
      }
      Log.d(TAG, 'Null sipConnection or call, try wait for a while');
      await Future.delayed(Duration(milliseconds: 500));
    }
    if (call.direction != 'INCOMING') {
      Log.e(TAG, 'It is not incoming call');
      return;
    }
    call.answer(helper.buildCallOptions(true));
  }

  Future<void> handleHangup() async {
    await stopSound();
    if (pendingCall != null) {
      pendingCall.cancel();
    }
    if (call != null) {
      try {
        call.hangup();
      } catch (ex) {
        Log.e(TAG, ex.toString());
      }
    }
    call = null;
  }

  Future<void> switchCamera() async {
    if (localStream != null) {
      await Helper.switchCamera(localStream.getVideoTracks()[0]);
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
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void registrationStateChanged(RegistrationState registrationState) {
    registerState = registrationState;
    Log.w(TAG,
        ' --- Register state ${registerState.state.toString()}, ${registerState.cause.toString()}');

    if (registrationState.state == RegistrationStateEnum.REGISTERED) {
      //_helper.call('sip:83952959223@calls.223-223.ru', false); // падает, если с видео
      isRegistered = true;
    } else {
      isRegistered = false;
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    print('-------------TRANSPORT state ${state.state.toString()}, cause ${state.cause.toString()}');
  }
}
