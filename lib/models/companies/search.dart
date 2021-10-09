import 'package:flutter/material.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/widgets/companies/cat_row.dart';
import 'package:masterme_chat/widgets/companies/company_row.dart';

class SearchModel {
  final Function setStateCallback;

  SearchModel({this.setStateCallback});

  String _query = '';
  String get query => _query;

  List<Widget> searchResult = [];

  Future<void> onQueryChanged(String query) async {
    if (query == _query) {
      return;
    }
    _query = query;
    if (query.isEmpty) {
      searchResult.clear();
      setStateCallback(
          {'searchResult': searchResult, 'searchProcessing': false});
      return;
    } else {
      setStateCallback({'searchProcessing': true});

      searchResult.clear();
      // Поиск по рубрикам
      final searchCatalogue = await Catalogue.searchCatalogue(query);
      final searchOrgs = await Orgs.searchOrgs(query);

      final searchPhones = await Phones.searchPhones(query);
      final orgsByPhones = await Orgs.getOrgsByPhones(searchPhones);

      final int catLen = searchCatalogue.length;
      final int orgsLen = searchOrgs.length;
      final int orgsByPhonesLen = orgsByPhones.length;

      final int totalLen = catLen + orgsLen + orgsByPhonesLen;
      searchResult = List.generate(totalLen, (i) {
        if (i >= catLen + orgsLen) {
          int j = i - (catLen + orgsLen);
          Orgs company = orgsByPhones[j];
          return Container(
            width: double.infinity,
            child: CompanyRow(company),
          );
        } else if (i >= catLen) {
          int j = i - catLen;
          Orgs company = searchOrgs[j];
          return Container(
            width: double.infinity,
            child: CompanyRow(company),
          );
        } else {
          Catalogue cat = searchCatalogue[i];
          return Container(
            width: double.infinity,
            child: CatRow(cat),
          );
        }
      });
    }
    setStateCallback({'searchResult': searchResult, 'searchProcessing': false});
  }
}
