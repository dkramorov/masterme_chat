import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/add2roster.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/screens/home.dart';
import 'package:masterme_chat/screens/login.dart';
import 'package:masterme_chat/screens/registration.dart';
import 'package:masterme_chat/screens/roster.dart';
import 'package:masterme_chat/screens/settings.dart';

import 'constants.dart';
import 'helpers/log.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '8800 help',
      theme: ThemeData.light().copyWith(
        primaryColor: PRIMARY_BG_COLOR,
        //scaffoldBackgroundColor: PRIMARY_BG_COLOR,
      ),
      initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => HomeScreen(),
        ChatScreen.id: (context) => ChatScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        RosterScreen.id: (context) => RosterScreen(),
        Add2RosterScreen.id: (context) => Add2RosterScreen(),
        SettingsScreen.id: (context) => SettingsScreen(),
      },
    );
  }
}