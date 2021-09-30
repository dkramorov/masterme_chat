import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/logic/login_logic.dart';
import 'package:masterme_chat/screens/register/reg_wizard_screen.dart';
import 'package:masterme_chat/screens/registration.dart';

class RegLinks extends StatelessWidget {
  static const TAG = 'RegLinks';
  final LoginScreenLogic logic;
  RegLinks(this.logic);

  Future<void> regProcess(BuildContext context, String type) async {
    Object result = await Navigator.pushNamed(
      context,
      RootWizardScreen.id,
      arguments: {
        'type': type,
      }
    );
    if (result != null && result == 1) {
      UserChatModel user = await logic.userFromDb();
      Log.d(TAG, 'authorization with ${user.login}, ${user.passwd}');
      if (user != null) {
        logic.authorization(user.login, user.passwd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _sgnNoAccTextStyle = Theme.of(context).textTheme.subtitle2;
    return Container(
      margin: PAD_SYM_V20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            SGN_NOACC_TEXT,
            style: _sgnNoAccTextStyle,
          ),
          GestureDetector(
            onTap: () {
              // Переход на регистрацию/восставновление пароля
              regProcess(context, 'reg');
            },
            child: Text(
              SGN_SIGNUP_TEXT,
              style: _sgnNoAccTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
          SIZED_BOX_H30,
          GestureDetector(
            onTap: () {
              // Переход на регистрацию/восставновление пароля
              regProcess(context, 'restore_passwd');
            },
            child: Text(
              SGN_FORGET_PASSWD_TEXT,
              style: _sgnNoAccTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
          SIZED_BOX_H30,
        ],
      ),
    );
  }
}
