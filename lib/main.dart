import 'dart:io';

import 'package:flutter/material.dart';

import 'package:masterme_chat/screens/add2roster.dart';
import 'package:masterme_chat/screens/auth/auth.dart';
import 'package:masterme_chat/screens/call.dart';
import 'package:masterme_chat/screens/call/incoming_call.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/screens/companies/companies_listing_screen.dart';
import 'package:masterme_chat/screens/companies/company_wizard_screen.dart';
import 'package:masterme_chat/screens/core/root_wizard_screen.dart';
import 'package:masterme_chat/screens/login.dart';
import 'package:masterme_chat/screens/register/reg_wizard_screen.dart';
import 'package:masterme_chat/screens/registration.dart';
import 'package:masterme_chat/screens/roster.dart';
import 'package:masterme_chat/screens/settings.dart';
import 'package:masterme_chat/screens/test.dart';

import 'package:masterme_chat/services/push_manager.dart';
import 'package:masterme_chat/services/telegram_bot.dart';

import 'constants.dart';

class MyHttpOverrides extends HttpOverrides {

  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (DB_SERVER.contains(host)) {
          return true;
        }
        return false;
      };
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details); // Standard behaviour

    TelegramBot().sendError(details.exception.toString());
    TelegramBot().sendError(details.stack.toString());

    print("----------------------");
    print("Error From INSIDE FRAME_WORK");
    print("Error :  ${details.exception}");
    print("StackTrace :  ${details.stack}");
    print("----------------------");
  };

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushNotificationsManager.materialKey,
      debugShowCheckedModeBanner: false,
      title: '8800 help',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.green,
        //scaffoldBackgroundColor: PRIMARY_BG_COLOR,
      ),
      initialRoute: RootScreen.id,
      //initialRoute: IncomingCallScreen.id,
      routes: {
        //HomeScreen.id: (context) => HomeScreen(), // Depricated
        ChatScreen.id: (context) => ChatScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        RosterScreen.id: (context) => RosterScreen(),
        Add2RosterScreen.id: (context) => Add2RosterScreen(),
        SettingsScreen.id: (context) => SettingsScreen(),
        CallScreen.id: (context) => CallScreen(),
        TestScreen.id: (context) => TestScreen(),
        //ChatVariant3.id: (context) => ChatVariant3(),

        RootScreen.id: (context) => RootScreen(),
        AuthScreen.id: (context) => AuthScreen(),
        RootWizardScreen.id: (context) => RootWizardScreen(),

        CompaniesListingScreen.id: (context) => CompaniesListingScreen(),
        CompanyWizardScreen.id: (context) => CompanyWizardScreen(),

        //IncomingCallScreen.id: (context) => IncomingCallScreen(),
      },
    );
  }
}
