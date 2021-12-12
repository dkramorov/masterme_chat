import 'dart:async';

import 'package:all_sensors/all_sensors.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';
import 'package:masterme_chat/widgets/companies/company_logo.dart';
import 'package:masterme_chat/widgets/phone/action_button.dart';
import 'package:masterme_chat/widgets/phone/phone_helpers.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  static const String id = '/call_screen/';

  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;
  final bool inScaffold;

  CallScreen(
      {this.pageController,
      this.setStateCallback,
      this.userData,
      this.inScaffold = true});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const String TAG = 'CallScreen';
  CallScreenLogic logic;

  bool inCallState = false;
  bool incomingInProgress = false;

  bool audioMuted = false;
  bool speakerOn = false;
  String inCallTime = '00:00';

  final GlobalKey<FormState> phoneFormKey = GlobalKey();
  final PhoneFormatter phoneFormatter = PhoneFormatter();

  String phoneNumber = '8';
  String inCallPhoneNumber = '';
  Orgs company;

  TextEditingController _phoneController = new TextEditingController();

  StreamSubscription proximitySubscription;

  @override
  void initState() {
    Log.d(TAG, 'initState');
    logic = CallScreenLogic(setStateCallback: setStateCallback);
    if (_phoneController.text != phoneNumber) {
      _phoneController.text = phoneNumber;
    }
    /* Если тык с истории был, то номер подставляем и забываем его
    TODO: а что если это история по фирме?
    */
    if (widget.userData != null) {
      final String phoneFromHistory = widget.userData['phoneFromHistory'];
      if (phoneFromHistory != null) {
        phoneNumber = phoneMaskHelper(phoneFromHistory);
        _phoneController.text = phoneNumber;
        widget.userData['phoneFromHistory'] = null;
      }
    }
    logic.parseArguments(context);
    Future.delayed(Duration.zero).then((_) async {
      if (mounted) {
        logic.checkUserReg();
        logic.checkState();
      }
    });
    super.initState();
  }

  @override
  void deactivate() {
    logic.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    logic.dispose();
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

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    if (state['phoneNumber'] != null && state['phoneNumber'] != phoneNumber) {
      setState(() {
        phoneNumber = state['phoneNumber'];
        _phoneController.text = phoneNumber;
      });
    }
    if (state['company'] != null && state['company'] != company) {
      setState(() {
        company = state['company'];
      });
    }
    if (state['inCallState'] != null && state['inCallState'] != inCallState) {
      setState(() {
        inCallState = state['inCallState'];
        if (inCallState) {
          listenProximitySensor();
        } else {
          stopListenProximitySensor();
        }
      });
    }
    if (state['inCallPhoneNumber'] != null &&
        state['inCallPhoneNumber'] != inCallPhoneNumber) {
      setState(() {
        inCallPhoneNumber = state['inCallPhoneNumber'];
      });
    }
    if (state['audioMuted'] != null && state['audioMuted'] != audioMuted) {
      setState(() {
        audioMuted = state['audioMuted'];
      });
    }
    if (state['speakerOn'] != null && state['speakerOn'] != speakerOn) {
      setState(() {
        speakerOn = state['speakerOn'];
      });
    }
    if (state['inCallTime'] != null && state['inCallTime'] != inCallTime) {
      setState(() {
        inCallTime = state['inCallTime'];
      });
    }
    if (state['incomingInProgress'] != null &&
        state['incomingInProgress'] != incomingInProgress) {
      setState(() {
        incomingInProgress = state['incomingInProgress'];
      });
    }
  }

  void handleKeyPad(String digit) {
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
  Future<void> callFormSubmit() async {
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

    bool hasPerm = await permsCheck(Permission.microphone, 'микрофон', context);
    if (hasPerm) {
      logic.makeCall(phoneNumber);
    }
  }

  void _clearPhone() {
    setState(() {
      phoneNumber = '8';
      _phoneController.text = '8';
    });
  }

  List<Widget> buildCallButtons() {
    if (incomingInProgress) {
      return [
        ActionButton(
          title: 'принять',
          icon: Icons.phone,
          onPressed: () {
            logic.acceptCall();
            setState(() {
              incomingInProgress = false;
            });
          },
          fillColor: Colors.green,
        ),
        ActionButton(
          title: 'отклонить',
          icon: Icons.call_end,
          onPressed: () {
            logic.hangup();
          },
          fillColor: Colors.red,
        ),
      ];
    }

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

  Widget buildCompanyInfo() {
    print(company);
    if (company == null) {
      return SizedBox();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CompanyLogoWidget(company),
            title: Text(
              company.name,
              overflow: TextOverflow.ellipsis,
              style: new TextStyle(
                fontSize: 20.0,
                color: new Color(0xFF212121),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  phoneNumber != null ? phoneNumber : '',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          children: buildNumPad(handleKeyPad),
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
            Text(inCallPhoneNumber),
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

    if (!widget.inScaffold) {
      return Container(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildDialPad(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
            buildCompanyInfo(),
            Container(
              padding: EdgeInsets.symmetric(vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildDialPad(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
