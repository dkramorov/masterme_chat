import 'package:flutter/material.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/screens/call.dart';

import 'package:masterme_chat/screens/login.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/screens/registration.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/services/push_manager.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  // Обязательно '/' без него завалится все нахер
  static const String id = '/';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  String appVersion = '';
  String title = 'Приветствуем';
  bool test = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> pushMessagesInit() async {
    final PushNotificationsManager pushManager = PushNotificationsManager();
    await pushManager.init();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version + '+' + info.buildNumber;
    });
  }

  Future<void> _initHealthcheck() async {
    JabberConn.healthcheck();
  }

  /* Пропускаем первую страничку и идем на вторую */
  Future<void> passMainPage() async {
    if (JabberConn.connection != null && JabberConn.connection.authenticated) {
      return;
    }
    UserChatModel user = await UserChatModel.getLastLoginUser();
    // Если мы нашли юзера и мы на этой страничке
    if(user != null && ModalRoute.of(context).isCurrent) {
      // Пока убираем переход на авторизацию в чат
      //Navigator.pushNamed(context, LoginScreen.id);
    }
  }

  @override
  void initState() {
    super.initState();
    pushMessagesInit();
    _initHealthcheck();
    _initPackageInfo();
    passMainPage();
  }

  @override
  Widget build(BuildContext context) {
    /*
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null && !test) {
      test = true;
      setState(() {
        title = arguments.toString();
      });
    }
     */

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 40.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: LOGO_SIZE,
                        color: Colors.green,
                      ),
                      SizedBox(
                        width: 15.0,
                      ),
                      Text(
                        LOGO_NAME,
                        style: SUBTITLE_STYLE,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 35.0,
                      ),
                      RoundedButtonWidget(
                        text: Text(
                          'Бесплатные звонки',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.green[500],
                        onPressed: () {
                          Navigator.pushNamed(context, CallScreen.id);
                        },
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      RoundedButtonWidget(
                        text: Text(
                          'Войти в чат',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.green[500],
                        onPressed: () {
                          Navigator.pushNamed(context, LoginScreen.id);
                        },
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      RoundedButtonWidget(
                        text: Text(
                          'Регистрация',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.green[500],
                        onPressed: () {
                          Navigator.pushNamed(context, RegistrationScreen.id, arguments: {
                          'type': 'reg',
                          });
                        },
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      RoundedButtonWidget(
                        text: Text(
                          'Сменить пароль',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.green[500],
                        onPressed: () {
                          Navigator.pushNamed(context, RegistrationScreen.id, arguments: {
                            'type': 'reset_passwd',
                          });
                        },
                      ),
                      /*
                      SizedBox(
                        height: 15.0,
                      ),
                      RoundedButtonWidget(
                        text: Text(
                          'Настройки',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.green[500],
                        onPressed: () {
                          Navigator.pushNamed(context, SettingsScreen.id);
                        },
                      ),
                       */
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                child: Text(
                  appVersion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
