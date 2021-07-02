import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/screens/home.dart';
import 'package:masterme_chat/screens/login.dart';
import 'package:masterme_chat/screens/registration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Чат',
      theme: ThemeData.dark().copyWith(
        primaryColor: PRIMARY_BG_COLOR,
        scaffoldBackgroundColor: PRIMARY_BG_COLOR,
      ),
      initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => HomeScreen(),
        ChatScreen.id: (context) => ChatScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
      },
    );
  }
}