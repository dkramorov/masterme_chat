import 'dart:async';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/settings_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/models/comanies_update.dart';
import 'package:masterme_chat/models/companies/addresses.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/cat_contpos.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/models/companies/cats.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/models/companies_update_version.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/companies_manager.dart';
import 'package:masterme_chat/services/update_manager.dart';

class CompaniesScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CompaniesScreenLogic';

  Catalogue curCat;
  Orgs curCompany;

  int loadedAddresses = 0;
  int loadedBranches = 0;
  int loadedCatContpos = 0;
  int loadedCatalogue = 0;
  int loadedCats = 0;
  int loadedOrgs = 0;
  int loadedPhones = 0;

  bool loadCatalogueDone = false;

  bool allLoaded = false;

  CompaniesScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    checkState();
  }

  Future<void> loadCatalogue({bool force = false}) async {
    List<Catalogue> rubrics = await Catalogue.getFullCatalogue();
    if (rubrics.isEmpty) {
      await UpdateManager().loadCatalogue();
      Timer updateTimer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
        if (!loadCatalogueDone && CompaniesManager.catalogueLoaded) {
          loadCatalogueDone = true;
          List<Catalogue> rubrics = await Catalogue.getFullCatalogue();
          setStateCallback({'rubrics': rubrics});
        }
      });
    } else {
      setStateCallback({'rubrics': rubrics});
    }
  }

  /* curCat приезджает в аргументах, поэтому ждем их */
  Future<void> loadCompanies() async {
    if (!isActive) {
      Log.d(TAG, 'stopping, because non-active...');
      return;
    }
    if (curCat != null) {
      List<Orgs> companies = await Orgs.getCategoryOrgs(curCat.id);
      setStateCallback({'companies': companies});
    } else {
      Future.delayed(Duration(milliseconds: 250), () async {
        await loadCompanies();
      });
    }
  }

  /* curCat приезджает в аргументах, поэтому ждем их */
  Future<void> loadCompany() async {
    if (!isActive) {
      Log.d(TAG, 'stopping, because non-active...');
      return;
    }
    if (curCompany != null) {
      Orgs company = await Orgs.getOrg(curCompany.id);
      company.branchesArr = await Branches.getOrgBranches(curCompany.id);
      for (Branches branch in company.branchesArr) {
        if (branch.address != null) {
          branch.mapAddress = await Addresses.getAddress(branch.address);
        }
      }
      company.phonesArr = await Phones.getOrgPhones(curCompany.id);
      company.catsArr = await Cats.getOrgCats(curCompany.id);
      company.rubricsArr = await Catalogue.getCatsRubrics(company.catsArr);

      curCompany = company;
      setStateCallback({'curCompany': curCompany});
    } else {
      Future.delayed(Duration(milliseconds: 250), () async {
        loadCompany();
      });
    }
  }

  @override
  String getTAG() {
    return TAG;
  }

  /* Получение аргументов на вьюхе */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    Future.delayed(Duration.zero, () {
      final arguments = ModalRoute.of(context).settings.arguments as Map;
      if (arguments != null) {
        // Страничка категории
        curCat = arguments['curCat'];
        if (curCat != null) {
          setStateCallback({
            'title': curCat.name,
          });
          loadCompanies();
        }

        // Страничка компании
        curCompany = arguments['curCompany'];
        if (curCompany != null) {
          setStateCallback({
            'title': curCompany.name,
          });
          loadCompany();
        }
      }
    });
  }
}
