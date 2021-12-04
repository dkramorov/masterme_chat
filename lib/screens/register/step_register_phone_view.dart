import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/chat_registration.dart';
import 'package:masterme_chat/widgets/register/progress_bar.dart';
import 'package:masterme_chat/widgets/rounded_input_text.dart';
import 'package:masterme_chat/widgets/auth/submit_button.dart';

class StepRegisterPhoneView extends StatefulWidget {
  final PageController pageController;
  final Function setStateCallback;
  Map<String, dynamic> userData;

  StepRegisterPhoneView(
      {this.pageController, this.setStateCallback, this.userData});

  @override
  _StepRegisterPhoneViewState createState() => _StepRegisterPhoneViewState();
}

class _StepRegisterPhoneViewState extends State<StepRegisterPhoneView> {
  final Duration _durationPageView = Duration(milliseconds: 500);
  final Curve _curvePageView = Curves.easeInOut;
  final FocusScopeNode _scopeNode = FocusScopeNode();

  final GlobalKey<FormState> _regFormKey = GlobalKey<FormState>();

  static const _TOTAL_STEPS = 2;
  static const _CURRENT_STEP = 1;

  bool submitted = false;
  String _phone = '8';
  String _name = '';
  String _passwd = '';
  String _type = 'reg';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _scopeNode.dispose();
  }

  backPageView() {
    Navigator.pop(context);
    _scopeNode.unfocus();
  }

  nextPageView() {
    widget.pageController
        .animateToPage(1, curve: _curvePageView, duration: _durationPageView);
    _scopeNode.unfocus();
  }

  /* Отправка формы регистрации */
  Future<void> regFormSubmit() async {
    if (!_regFormKey.currentState.validate()) {
      return;
    }
    _regFormKey.currentState.save();

    if (submitted) {
      return;
    }
    submitted = true;
    widget.setStateCallback({
      'loading': true,
    });

    widget.userData['phone'] = _phone;
    widget.userData['name'] = _name;
    widget.userData['passwd'] = _passwd;

    final RegistrationModel reg =
        await RegistrationModel.requestRegistration(_phone, _name, _passwd);

    if (reg != null && reg.id != null) {
      nextPageView();
    } else {
      openInfoDialog(
        context,
        null,
        'Ошибка регистрации',
        'Не получен ответ от сервера, пожалуйста, попробуйте поздже',
        'Понятно',
      );
    }
    widget.setStateCallback({
      'loading': false,
    });
    submitted = false;
  }

  @override
  Widget build(BuildContext context) {
    final _sgpTitleTextStyle =
        Theme.of(context).textTheme.headline4.copyWith(color: Colors.black);
    final _sgpInputTextStyle = Theme.of(context).textTheme.subtitle2;

    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {
      _type = arguments['type'];
    }

    return Container(
      margin: PAD_ONLY_T40,
      padding: PAD_SYM_H20,
      child: Center(
        child: ListView(
          children: [
            PageViewProgressBar(
              backPageView: () => backPageView(),
              nextPageView: () => nextPageView(),
              totalStep: _TOTAL_STEPS,
              currentStep: _CURRENT_STEP,
            ),
            SIZED_BOX_H30,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _type == 'reg' ? SGP_ADD_PHONE_TEXT : SGP_RESTORE_PHONE_TEXT,
                  style: _sgpTitleTextStyle,
                  textAlign: TextAlign.center,
                ),
                SIZED_BOX_H30,
                Text(
                  SGP_PHONE_NOTICE_TEXT,
                  style: _sgpInputTextStyle.copyWith(color: kSubTextColor),
                  textAlign: TextAlign.center,
                ),
                SIZED_BOX_H30,
                Form(
                  key: _regFormKey,
                  child: Column(
                    children: [
                      RoundedInputText(
                        hint: SGN_PHONE_TEXT,
                        onChanged: (String text) {
                          setState(() {
                            _phone = text;
                          });
                        },
                        formatters: [PhoneFormatter()],
                        validator: (String value) {
                          bool match = phoneMaskValidator().hasMatch(value);
                          if (value.isEmpty || !match) {
                            return 'Например, $SGN_HINT_PHONE_TEXT';
                          }
                        },
                        keyboardType: TextInputType.number,
                        defaultValue: _phone,
                        prefixIcon: Icon(Icons.phone_android),
                        textAlign: TextAlign.left,
                      ),
                      SIZED_BOX_H30,
                      RoundedInputText(
                        hint: 'Ваше имя',
                        onChanged: (String text) {
                          setState(() {
                            _name = text;
                          });
                        },
                        validator: (String value) {
                          if (value.isEmpty) {
                            return 'Введите ваше имя';
                          }
                        },
                        defaultValue: _name,
                        prefixIcon: Icon(Icons.account_circle_rounded),
                        textAlign: TextAlign.left,
                      ),
                      SIZED_BOX_H30,
                      RoundedInputText(
                        hint: SGP_SETUP_PASS_TEXT,
                        onChanged: (String text) {
                          setState(() {
                            _passwd = text;
                          });
                        },
                        validator: (String value) {
                          if (value.isEmpty) {
                            return SGP_HINT_PASS_TEXT;
                          }
                        },
                        defaultValue: _passwd,
                        prefixIcon: Icon(Icons.shield),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SIZED_BOX_H30,
            Container(
              child: Center(
                child: SubmitButton(
                  text: SGP_SEND_OTP_TEXT,
                  onPressed: () {
                    regFormSubmit();
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
