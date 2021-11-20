import 'dart:async';

import 'package:all_sensors/all_sensors.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';
import 'package:masterme_chat/widgets/phone/action_button.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';

class CallScreen extends StatefulWidget {
  static const String id = '/call_screen/';

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final String TAG = 'CallScreen';
  CallScreenLogic logic;

  bool inCallState = false;
  bool curUserExists = false;

  bool audioMuted = false;
  bool speakerOn = false;
  String inCallTime = '00:00';

  final GlobalKey<FormState> phoneFormKey = GlobalKey();
  final PhoneFormatter phoneFormatter = PhoneFormatter();

  String phoneNumber = '8';

  TextEditingController _phoneController = new TextEditingController();

  StreamSubscription proximitySubscription;

  @override
  void dispose() {
    _phoneController.dispose();
    stopListenProximitySensor();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void stopListenProximitySensor() {
    if (proximitySubscription != null) {
      proximitySubscription.cancel();
      proximitySubscription = null;
    }
  }

  void listenProximitySensor() {
    if (proximitySubscription != null) {
      Log.d(TAG, 'proximity sensor already listening');
      return;
    }

    proximitySubscription = proximityEvents.listen((ProximityEvent event) {
      Log.d(TAG, '$event');
    });
  }

  @override
  initState() {
    logic = CallScreenLogic(setStateCallback: setStateCallback);
    if (_phoneController.text != phoneNumber) {
      _phoneController.text = phoneNumber;
    }
    super.initState();
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['inCallState'] != null && state['inCallState'] != inCallState) {
        inCallState = state['inCallState'];
        if (inCallState) {
          listenProximitySensor();
        } else {
          stopListenProximitySensor();
        }
      }
      if (state['curUserExists'] != null &&
          state['curUserExists'] != curUserExists) {
        curUserExists = state['curUserExists'];
      }
      if (state['audioMuted'] != null && state['audioMuted'] != audioMuted) {
        audioMuted = state['audioMuted'];
      }
      if (state['speakerOn'] != null && state['speakerOn'] != speakerOn) {
        speakerOn = state['speakerOn'];
      }
      if (state['inCallTime'] != null && state['inCallTime'] != inCallTime) {
        inCallTime = state['inCallTime'];
      }
    });
  }

  void _handleKeyPad(String digit) {
    if (inCallState) {
      logic.sendDTMF(digit);
      return;
    }
    setState(() {
      _phoneController.text = phoneMaskHelper(_phoneController.text + digit);
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: _phoneController.text.length,
        ),
      );
    });
  }

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _phoneController.text;
    if (text.isNotEmpty) {
      this.setState(() {
        text = deleteAll
            ? '8'
            : phoneMaskHelper(text.substring(0, text.length - 1));
        _phoneController.text = text;
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(
            offset: _phoneController.text.length,
          ),
        );
      });
    }
  }

  /* Отправка формы на звонок */
  void callFormSubmit() {
    if (!phoneFormKey.currentState.validate()) {
      return;
    }
    if (inCallState) {
      Log.i(TAG, 'already in call');
    }
    phoneFormKey.currentState.save();

    // Надо поменять статус и кнопки
    if (logic.sipConnection == null) {
      openInfoDialog(
          context,
          null,
          'Ответ от сервера',
          'Произошла ошибка, попробуйте зарегистрироваться повторно.' +
              'Если ошибка не исчезает, пожалуйста, сообщите нам',
          'Понятно');
      return;
    }
    logic.makeCall(phoneNumber);
  }

  void _clearPhone() {
    setState(() {
      phoneNumber = '8';
      _phoneController.text = '8';
    });
  }

  List<Widget> _buildError() {
    return [
      Container(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Сначала зарегистрируйтесь, чтобы звонить бесплатно',
          style: TextStyle(
            fontSize: 24.0,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildNumPad() {
    return CallScreenLogic.numPadLabels
        .map(
          (row) => Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map(
                    (label) => ActionButton(
                      title: '${label.keys.first}',
                      subTitle: '${label.values.first}',
                      onPressed: () => _handleKeyPad(label.keys.first),
                      number: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .toList();
  }

  List<Widget> buildCallButtons() {
    if (inCallState) {
      return [
        ActionButton(
          title: 'мик',
          icon: audioMuted ? Icons.mic_off : Icons.mic,
          checked: audioMuted,
          onPressed: () {
            logic.toggleMute();
          },
        ),
        ActionButton(
          title: "сброс",
          onPressed: () {
            logic.hangup();
          },
          icon: Icons.call_end,
          fillColor: Colors.red,
        ),
        ActionButton(
          title: 'спикер',
          icon: speakerOn ? Icons.volume_off : Icons.volume_up,
          checked: speakerOn,
          onPressed: () {
            logic.toggleSpeaker();
          },
        ),
      ];
    }
    return [
      ActionButton(
        icon: Icons.clear,
        onPressed: () => _clearPhone(),
      ),
      ActionButton(
        icon: Icons.dialer_sip,
        fillColor: Colors.green,
        onPressed: () => callFormSubmit(),
      ),
      ActionButton(
        icon: Icons.keyboard_arrow_left,
        onPressed: () => _handleBackSpace(),
        onLongPress: () => _handleBackSpace(true),
      ),
    ];
  }

  List<Widget> _buildDialPad() {
    return [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 330,
              padding: EdgeInsets.all(15.0),
              child: Form(
                key: phoneFormKey,
                child: RoundedInputText(
                  hint: 'Введите телефон, кому звоним',
                  controller: _phoneController,
                  onChanged: (String text) {
                    setState(() {
                      phoneNumber = text;
                    });
                  },
                  formatters: [phoneFormatter],
                  validator: (String value) {
                    bool match = phoneMaskValidator().hasMatch(value);
                    if (value.isEmpty || !match) {
                      return 'Введите телефон, кому звоним';
                    }
                  },
                  //keyboardType: TextInputType.number,
                  defaultValue: phoneNumber,
                  showCursor: true,
                  readOnly: true,
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildNumPad(),
        ),
      ),
      Container(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buildCallButtons(),
          ),
        ),
      ),
      Container(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(inCallTime),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero).then((_) async {
      if (mounted) {
        logic.checkUserReg();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Бесплатный звонок (SIP)",
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            /*
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                  child: Text(
                'Status: ${EnumHelper.getName(sipConnection.registerState.state)}',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),),
            ),
             */
            Container(
              padding: EdgeInsets.symmetric(vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: curUserExists ? _buildDialPad() : _buildError(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
