import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/screens/logic/companies_logic.dart';

class TabCompaniesView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;

  // Т/к виджет будет пересоздаваться из root_wizard_screen
  // надо сразу оттуда передавать данные по curUser & loggedIn
  UserChatModel curUser;
  bool loggedIn = false;

  TabCompaniesView({this.pageController, this.setStateCallback, this.userData});

  @override
  _TabCompaniesViewState createState() => _TabCompaniesViewState();
}

class _TabCompaniesViewState extends State<TabCompaniesView> {
  static const TAG = 'TabCompaniesView';
  CompaniesScreenLogic logic;

  @override
  void initState() {
    logic = CompaniesScreenLogic(setStateCallback: setStateCallback);
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void deactivate() {
    logic.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['history'] != null) {
        //history = state['history'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PAD_SYM_H10,
      child: Column(
        children: [
          Container(
            child: Text('Загружено филиалов'),
          ),
        ],
      ),
    );
  }
}
