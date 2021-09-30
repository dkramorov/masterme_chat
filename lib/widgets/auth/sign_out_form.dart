import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/core/root_wizard_screen.dart';
import 'package:masterme_chat/screens/logic/login_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/auth/submit_button.dart';

class SignOutForm extends StatelessWidget {
  final LoginScreenLogic logic;
  SignOutForm(this.logic);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: 10,
            bottom: 20,
          ),
          child: Text(
            JabberConn.curUser != null
                ? 'Вы авторизованы:\n' +
                    phoneMaskHelper(JabberConn.curUser.login)
                : 'Вы не авторизованы',
            style: GREEN_TEXT_STYLE,
          ),
        ),
        Center(
          child: SubmitButton(
            text: SGN_SIGNIN_TEXT,
            onPressed: () {
              Navigator.pushNamed(context, RootScreen.id);
            },
          ),
        ),
        SizedBox(
          height: 20.0,
        ),
        Center(
          child: SubmitButton(
            text: SGN_SIGNOUT_TEXT,
            onPressed: () {
              logic.logout();
            },
          ),
        ),
      ],
    );
  }
}
