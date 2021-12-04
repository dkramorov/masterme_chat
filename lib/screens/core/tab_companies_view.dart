import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/screens/logic/companies_logic.dart';
import 'package:masterme_chat/widgets/companies/cat_row.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/floating_search_widget.dart';

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

  List<Catalogue> rubrics = [];

  @override
  void initState() {
    logic = CompaniesScreenLogic(setStateCallback: setStateCallback);
    // Прогружаем данные
    logic.loadCatalogue();
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
      if (state['rubrics'] != null) {
        rubrics = state['rubrics'];
      }
    });
  }

  Widget buildFloatingSearch() {
    return Stack(
      children: [
        CompaniesFloatingSearchWidget(),
      ],
    );
  }

  /* Вкладка со всеми категориями */
  Widget buildCatalogue() {
    return rubrics.length == 0
        ? CatalogueInUpdate()
        : Column(
            children: [
              buildPanelForSearch(),
              Expanded(
                child: ListView.builder(
                  itemCount: rubrics.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  itemBuilder: (context, index) {
                    final item = rubrics[index];
                    return CatRow(item);
                  },
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildCatalogue(),
        buildFloatingSearch(),
      ],
    );
  }
}
