import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class Add2RosterScreen extends StatefulWidget {
  static const String id = '/add2roster_screen/';

  @override
  _Add2RosterScreenState createState() => _Add2RosterScreenState();
}

class _Add2RosterScreenState extends State<Add2RosterScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String newUser = '';

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  /* Отправка формы авторизации */
  void addUserFormSubmit() {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    final fullLogin = newUser.replaceAll(RegExp('[^0-9]+'), '') + '@' + JABBER_SERVER;
    var newUserJid = xmpp.Jid.fromFullJid(fullLogin);
    JabberConn.rosterManager.addRosterItem(xmpp.Buddy(newUserJid));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить контакт'),
      ),
      body: ModalProgressHUD(
        inAsyncCall: false,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 15.0,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Добавление нового контакта',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        RoundedInputText(
                          hint: 'Логин пользователя',
                          onChanged: (String text) {
                            setState(() {
                              newUser = text;
                            });
                          },
                          /*
                          validator: (String value) {
                            bool match = RegExp(r'^[a-z0-9]+@[a-z0-9\.]+$')
                                .hasMatch(value);
                            if (value.isEmpty || !match) {
                              return 'Неправильный логин';
                            }
                          },
                           */
                          formatters: [PhoneFormatter()],
                          validator: (String value) {
                            bool match =
                            RegExp(r'^8 \([0-9]{3}\) [0-9]{1}-[0-9]{3}-[0-9]{3}$')
                                .hasMatch(value);
                            if (value.isEmpty || !match) {
                              return 'Ваш телефон';
                            }
                          },
                          keyboardType: TextInputType.number,
                          defaultValue: '',
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        RoundedButtonWidget(
                          text: Text(
                            'Добавить',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.green[500],
                          onPressed: () {
                            addUserFormSubmit();
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
