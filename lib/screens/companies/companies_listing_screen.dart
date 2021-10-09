import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/screens/logic/companies_logic.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/company_row.dart';
import 'package:masterme_chat/widgets/companies/floating_search_widget.dart';

class CompaniesListingScreen extends StatefulWidget {
  static const String id = '/companies_listing_screen/';

  @override
  _CompaniesListingScreenState createState() => _CompaniesListingScreenState();
}

class _CompaniesListingScreenState extends State<CompaniesListingScreen> {
  static const TAG = 'CompaniesListingScreen';
  CompaniesScreenLogic logic;

  List<Orgs> companies = [];
  String title = 'Каталог компаний';

  @override
  void initState() {
    logic = CompaniesScreenLogic(setStateCallback: setStateCallback);
    logic.parseArguments(context);
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
      if (state['companies'] != null) {
        companies = state['companies'];
      }
      if (state['title'] != null) {
        title = state['title'];
      }
      if (state['loadedCats'] != null) {
        logic.loadCompanies();
      }
    });
  }

  Widget buildCatalogue() {
    if (companies.length == 0) {
      return CatalogueInUpdate();
    }
    return Column(
      children: [
        SIZED_BOX_H45,
        Expanded(
          child: ListView.builder(
            itemCount: companies.length,
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(
              vertical: 15,
            ),
            itemBuilder: (context, index) {
              final item = companies[index];
              return CompanyRow(item);
            },
          ),
        ),
      ],
    );
  }

  Widget buildFloatingSearch() {
    return Stack(
      children: [
        CompaniesFloatingSearchWidget(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
      ),
      body: Stack(
        children: [
          buildCatalogue(),
          buildFloatingSearch(),
        ],
      ),
    );
  }
}
