import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/models/chat_registration.dart';
import 'package:masterme_chat/widgets/register/progress_bar.dart';
import 'package:masterme_chat/widgets/auth/submit_button.dart';

class StepConfirmPhoneView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;

  StepConfirmPhoneView(
      {this.pageController, this.setStateCallback, this.userData});

  @override
  _StepConfirmPhoneViewState createState() => _StepConfirmPhoneViewState();
}

class _StepConfirmPhoneViewState extends State<StepConfirmPhoneView> {
  static const TAG = 'StepConfirmPhoneView';
  final Duration _durationPageView = Duration(milliseconds: 500);
  final Curve _curvePageView = Curves.easeInOut;

  static const _TOTAL_STEPS = 2;
  static const _CURRENT_STEP = 2;
  static const _OTP_SIZE = 4;
  List<OtpField> otpList = [];

  // This use to switch from a TextField to anothers.
  final FocusScopeNode _scopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _scopeNode.dispose();
  }

  /* Отправка формы кода подтверждения */
  Future<void> regConfirmCodeFormSubmit() async {
    if (widget.userData['phone'] == null) {
      openInfoDialog(
        context,
        null,
        'Не введен номер телефона',
        'Вернитесь к вводу номера телефона',
        'Понятно',
      );
      return;
    }
    String confirmCode = getOtpValue();
    if (confirmCode.length != _OTP_SIZE) {
      openInfoDialog(
        context,
        null,
        'Не введен проверочный код',
        'Введите 4 цифры проверочного кода, который вы получили по телефону',
        'Понятно',
      );
      return;
    }

    widget.setStateCallback({
      'loading': true,
    });
    final confirm = await RegistrationModel.confirmRegistration(
        widget.userData['phone'], confirmCode);
    if (confirm != null && confirm.message != null) {
      if (confirm.code == RegistrationModel.CODE_PASSWD_CHANGED) {
        openInfoDialog(context, userConfirmed, 'Ответ от сервера',
            confirm.message, 'Понятно');
      } else if (confirm.code == RegistrationModel.CODE_REGISTRATION_SUCCESS) {
        openInfoDialog(context, userConfirmed, 'Ответ от сервера',
            confirm.message, 'Понятно');
      } else if (confirm.code == RegistrationModel.CODE_ERROR) {
        openInfoDialog(context, nextPageView, 'Ответ от сервера',
            confirm.message, 'Понятно');
      }
    }
    widget.setStateCallback({
      'loading': false,
    });
  }

  /* Регистрация пройдена или
     паролька изменена,
     записываем пользователя
     переходим на авторизацию (а автологином)
   */
  Future<void> userConfirmed() async {
    await UserChatModel.insertLastLoginUser(
      widget.userData['phone'],
      widget.userData['passwd'],
      name: widget.userData['name'],
    );
    // Возвращаем 1
    Navigator.pop(context, 1);
  }

  // Get value of OTP when user done
  String getOtpValue() {
    String _otpString = '';
    otpList.forEach((otp) =>
        _otpString = otp.value != null ? _otpString += otp.value : _otpString);
    return _otpString;
  }

  otpGenerate(int length) => List<OtpField>.generate(length, (index) {
        if (index == 0)
          return OtpField(isStart: true, onFocus: true);
        else
          return OtpField();
      })
        ..forEach((otp) {
          otp.scopeNode = _scopeNode;
          otpList.add(otp);
        })
        ..last.isEnd = true;

  // Back the previous PageView
  backPageview() {
    widget.pageController
        .animateToPage(0, curve: _curvePageView, duration: _durationPageView);
    _scopeNode.unfocus();
  }

  // Forward the next PageView
  nextPageView() {
    widget.pageController
        .animateToPage(2, curve: _curvePageView, duration: _durationPageView);
    _scopeNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final _sgpTitleTextStyle =
        Theme.of(context).textTheme.headline4.copyWith(color: Colors.black);
    final _sgpSendMessageTextStyle = Theme.of(context).textTheme.subtitle2;

    final _screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: PAD_ONLY_T40,
      padding: PAD_SYM_H20,
      child: Center(
        child: ListView(
          children: [
            PageViewProgressBar(
              backPageView: () => backPageview(),
              nextPageView: () => nextPageView(),
              totalStep: _TOTAL_STEPS,
              currentStep: _CURRENT_STEP,
            ),
            SIZED_BOX_H30,
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    SGP_VERIFY_NUMBER_TEXT,
                    style: _sgpTitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  SIZED_BOX_H30,
                  Text(
                    '$SGP_SEND_MESSAGE_TEXT',
                    style: _sgpSendMessageTextStyle.copyWith(
                        color: kSubTextColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  SIZED_BOX_H30,
                  Container(
                    margin: PAD_SYM_V20,
                    alignment: Alignment.center,
                    width: _screenWidth / 2,
                    child: FocusScope(
                      node: _scopeNode,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: otpGenerate(_OTP_SIZE),
                      ),
                    ),
                  ),
                  /*
                  SIZED_BOX_H30,
                  Text(
                    SGP_RESEND_TEXT,
                    style: _sgpSendMessageTextStyle.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   */
                ],
              ),
            ),
            SIZED_BOX_H30,
            Container(
              child: Center(
                child: SubmitButton(
                  text: SGP_CONFIRM_TEXT,
                  onPressed: () {
                    regConfirmCodeFormSubmit();
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

class OtpField extends StatefulWidget {
  OtpField({
    this.isEnd = false,
    this.isStart = false,
    this.scopeNode,
    this.onFocus = false,
    this.value,
  });
  bool isStart;
  bool isEnd;
  FocusScopeNode scopeNode;
  bool onFocus;
  String value;

  @override
  _OtpFieldState createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  hideHasValueBox(String value) {
    // Set value for parent get OTP when user done
    setState(() {
      widget.value = value.isNotEmpty ? value : null;
    });

    // When user type a TextField, If that Input have a value, forward next one.
    // When user remove a value in TextField, backward previous one
    if (widget.value != null) {
      if (!widget.isEnd) {
        widget.scopeNode.nextFocus();
      } else {
        widget.scopeNode.unfocus();
      }
    } else if (!widget.isStart) {
      widget.scopeNode.previousFocus();
    } else {
      widget.scopeNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 6,
          left: 10,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.value != null
                  ? Colors.transparent
                  : kDisabledButtonColor,
            ),
          ),
        ),
        // Main TextField for OTP
        Container(
          width: 40.0,
          height: 40.0,
          child: TextField(
            // Input acceptable for number and only 1 number for each TextField
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9]')),
              LengthLimitingTextInputFormatter(1),
            ],
            autofocus: widget.onFocus,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            cursorHeight: 0,
            cursorColor: Colors.transparent,
            cursorWidth: 0,
            style: Theme.of(context).textTheme.headline3,
            keyboardType: TextInputType.number,
            onChanged: (value) => hideHasValueBox(value),
          ),
        ),
      ],
    );
  }
}
