import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/call.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';
import 'package:masterme_chat/services/push_manager.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:masterme_chat/widgets/phone/action_button.dart';

/* USAGE
Overlay который перекрывает нам основной экран

в виджете
  OverlayEntry callOverlay; // слой звонка

в initState
  // слой звонка
  showInCallOverlay(callOverlay, context);

*/

void showInCallOverlay(String payload) {
  if (SipConnection.isOverlayVisible) {
    Log.w('showInCallOverlay', 'already visible');
    return;
  }

  final List<String> parts = payload.split('=>');
  final String sender = parts[0].replaceAll('call_', '');
  final String receiver = parts[1];

  SipConnection.isOverlayVisible = true;
  if (CallOverlay.overlayEntry != null) {
    Log.w('showInCallOverlay', 'Looks like call overlay already open');
    return;
  }
  if (WidgetsBinding.instance == null) {
    Log.w('showInCallOverlay', '--- WidgetsBindings.instance is null ---');
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Log.d('showInCallOverlay', '--- addPostFrameCallback started ---');
    CallOverlay.overlayEntry = OverlayEntry(builder: (context) {
      Log.d('showInCallOverlay', '--- overlay builder processing ---');
      return CallOverlay(sender: sender, receiver: receiver);
    });
    PushNotificationsManager.materialKey.currentState.overlay
        .insert(CallOverlay.overlayEntry);
  });
}

void hideInCallOverlay(CallScreenLogic logic,
    {bool nav2call: false, ContactChatModel contact}) {
  SipConnection.isOverlayVisible = false;
  SipConnection.stopSound();
  PushNotificationsManager.localNotificationsPlugin
      .cancel(PushNotificationsManager.NOTIFICATION_ID_CALL);

  if (CallOverlay.overlayEntry == null) {
    print('--- OverlayEntry is null ---');
    return;
  }
  CallOverlay.overlayEntry.remove();
  CallOverlay.overlayEntry = null;
  logic.dispose();

  if (nav2call) {
    Navigator.of(PushNotificationsManager.materialKey.currentContext)
        .popUntil((route) => route.settings.name != CallScreen.id);

    PushNotificationsManager.materialKey.currentState
        .pushNamed(CallScreen.id, arguments: {
      'curPhoneStr': SipConnection.inCallPhoneNumber,
      'isSip': true,
      'curContact': contact,
    });
  }
}

class CallOverlay extends StatefulWidget {
  static OverlayEntry overlayEntry;
  final String sender;
  final String receiver;

  CallOverlay({this.sender, this.receiver});

  @override
  _CallOverlayState createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  static const String TAG = 'CallOverlay';
  CallScreenLogic logic;
  bool isIncomingReady = false;
  ContactChatModel contact;

  @override
  void initState() {
    Log.d(TAG, 'initState, init sip');
    logic = CallScreenLogic(setStateCallback: setStateCallback);
    // Инициируем sip и отменяем уведомление
    SipConnection().init(widget.receiver);
    // Так работает, но сразу душит уведомление
    //PushNotificationsManager.localNotificationsPlugin.cancelAll();
    SipConnection.callManagerState = CallManagerState.IncomingStarted;
    super.initState();

    Future.delayed(Duration.zero, () async {
      getContact();
    });
  }

  @override
  void dispose() {
    Log.w(TAG, 'dispose overlay');
    logic.dispose();
    super.dispose();
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    if (state['incomingInProgress'] != null &&
        isIncomingReady != state['incomingInProgress']) {
      setState(() {
        isIncomingReady = state['incomingInProgress'];
      });
    }
    if (SipConnection.callManagerState == CallManagerState.Idle) {
      hideInCallOverlay(logic);
    } else if (state['incomingInProgress'] != null &&
        isIncomingReady &&
        state['incomingInProgress'] != isIncomingReady) {
      hideInCallOverlay(logic);
    }
  }

  Future<ContactChatModel> getContact() async {
    if (contact == null) {
      String me = '${widget.receiver}@$JABBER_SERVER';
      String friend = '${widget.sender}@$JABBER_SERVER';
      ContactChatModel user = await ContactChatModel.getByLogin(me, friend);
      contact = user;
    }
    return contact;
  }

  Widget buildAvatar(String avatar) {
    if (avatar == null) {
      avatar = DEFAULT_AVATAR;
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.transparent,
      backgroundImage: AssetImage(avatar),
    );
  }

  Widget buildContactInfo(ContactChatModel contact) {
    if (contact == null) {
      return SizedBox();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        contact.buildAvatar(),
        SIZED_BOX_H06,
        Text(
          contact.getName(),
          overflow: TextOverflow.ellipsis,
          style: new TextStyle(
            fontSize: 20.0,
            color: new Color(0xFF212121),
            fontWeight: FontWeight.bold,
          ),
        ),
        SIZED_BOX_H06,
        Text(
          phoneMaskHelper(contact.login),
          style: TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  Widget buildConnecting2Sip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Text('Пожалуйста, подождите, устанавливается соединение...'),
        ),
        SIZED_BOX_H20,
        ActionButton(
          title: 'отклонить',
          icon: Icons.call_end,
          onPressed: () {
            hideInCallOverlay(logic);
            logic.hangup();
          },
          fillColor: Colors.red,
        ),
      ],
    );
  }

  Widget buildCallButtons() {
    /* Кнопки принятия/отклонения звонка */
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          title: 'принять',
          icon: Icons.phone,
          onPressed: () {
            hideInCallOverlay(logic, nav2call: true, contact: contact);
            logic.acceptCall();
          },
          fillColor: Colors.green,
        ),
        ActionButton(
          title: 'отклонить',
          icon: Icons.call_end,
          onPressed: () {
            hideInCallOverlay(logic);
            logic.hangup();
          },
          fillColor: Colors.red,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Без Material будет желтое подчеркивание под текстом (говнотема)
    String aon = phoneMaskHelper(widget.sender);
    print('--- BUILD: CallOverlay ---');
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.white.withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<ContactChatModel>(
                future: getContact(),
                builder: (BuildContext context,
                    AsyncSnapshot<ContactChatModel> snapshot) {
                  if (snapshot.hasData) {
                    return buildContactInfo(snapshot.data);
                  } else {
                    return Text(
                      aon,
                      style: TextStyle(
                        fontSize: 22.0,
                      ),
                    );
                  }
                }),
            /*
            Text(
              aon,
              style: TextStyle(
                fontSize: 22.0,
              ),
            ),
            */
            SIZED_BOX_H45,
            //isIncomingReady ? buildCallButtons() : buildConnecting2Sip(),
            buildCallButtons(), // Показываем кнопки сразу принять/отклонить
          ],
        ),
      ),
    );
  }
}
