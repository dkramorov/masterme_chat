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

class CompaniesScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CompaniesScreenLogic';

  static int defaultUpdateInterval = (60 * 30 ~/ 2); // полчасика
  //static int defaultUpdateInterval = 10;
  static int intervalUpdateCheck = defaultUpdateInterval;

  Catalogue curCat;
  Orgs curCompany;

  int loadedAddresses = 0;
  int loadedBranches = 0;
  int loadedCatContpos = 0;
  int loadedCatalogue = 0;
  int loadedCats = 0;
  int loadedOrgs = 0;
  int loadedPhones = 0;

  bool allLoaded = false;

  CompaniesScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    checkState();

    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();

      CompaniesScreenLogic.intervalUpdateCheck -= 1;
      //Log.d(TAG, 'next update check in ${CompaniesScreenLogic.intervalUpdateCheck}');
      if (CompaniesScreenLogic.intervalUpdateCheck < 0) {
        CompaniesScreenLogic.intervalUpdateCheck = defaultUpdateInterval;
        int version = await CompaniesUpdateVersion.downloadUpdateVersion();
        if (version > 0) {
          int curVersion = await SettingsModel.getUpdateVersion();
          if (curVersion == null || curVersion < version) {
            await SettingsModel.setUpdateVersion(version);
            await CompaniesUpdate.dropUpdate();
            loadCatalogue(force: true);
          }
        }
      }
      //Log.d(TAG, '${t.tick}');
    });
  }

  Future<void> loadCatalogue({bool force = false}) async {
    List<Catalogue> rubrics = await Catalogue.getFullCatalogue();
    if (rubrics.isEmpty) {
      // При первом запуске
      // Получаем с сервачка версию бд и пишем в базень
      int version = await CompaniesUpdateVersion.downloadUpdateVersion();
      if (version > 0) {
        await SettingsModel.setUpdateVersion(version);
      }
      await loadCompaniesUpdate(key: 'Catalogue');
    } else {
      setStateCallback({'rubrics': rubrics});

      if (CompaniesManager.allLoaded() && !force) {
        return;
      }

      /* Проверяем количество в остальных таблицах */
      CompaniesUpdate data = await CompaniesUpdate.parseUpdateFile();
      Log.d(TAG, 'Check other data: $data');

      if (!CompaniesManager.catContposLoaded || force) {
        int catContposCount = await CatContpos().getCount();
        if (catContposCount < data.catContpos.length || force) {
          await saveData(data, key: 'CatContpos');
          return;
        } else {
          CompaniesManager.catContposLoaded = true;
        }
      }

      if (!CompaniesManager.catalogueLoaded || force) {
        int catalogueCount = await Catalogue().getCount();
        if (catalogueCount < data.catalogue.length || force) {
          await saveData(data, key: 'Catalogue');
          return;
        } else {
          CompaniesManager.catalogueLoaded = true;
        }
      }

      if (!CompaniesManager.catsLoaded || force) {
        int catsCount = await Cats().getCount();
        if (catsCount < data.cats.length || force) {
          await saveData(data, key: 'Cats');
          return;
        } else {
          CompaniesManager.catsLoaded = true;
        }
      }

      if (!CompaniesManager.orgsLoaded || force) {
        int orgsCount = await Orgs().getCount();
        if (orgsCount < data.orgs.length || force) {
          await saveData(data, key: 'Orgs');
          return;
        } else {
          CompaniesManager.orgsLoaded = true;
        }
      }

      if (!CompaniesManager.branchesLoaded || force) {
        int branchesCount = await Branches().getCount();
        if (branchesCount < data.branches.length || force) {
          await saveData(data, key: 'Branches');
          return;
        } else {
          CompaniesManager.branchesLoaded = true;
        }
      }

      if (!CompaniesManager.phonesLoaded || force) {
        int phonesCount = await Phones().getCount();
        if (phonesCount < data.phones.length || force) {
          await saveData(data, key: 'Phones');
          return;
        } else {
          CompaniesManager.phonesLoaded = true;
        }
      }

      if (!CompaniesManager.addressesLoaded || force) {
        int addressesCount = await Addresses().getCount();
        if (addressesCount < data.addresses.length || force) {
          await saveData(data, key: 'Addresses');
          return;
        } else {
          CompaniesManager.addressesLoaded = true;
        }
      }
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
      curCompany = company;
      setStateCallback({'curCompany': curCompany});
    } else {
      Future.delayed(Duration(milliseconds: 250), () async {
        loadCompany();
      });
    }
  }

  /* Сохранение всего говнища в базу */
  Future<void> saveData(CompaniesUpdate data, {String key}) async {
    // Т/к мы вставляем (?,?,?), (?,?,?)... то есть, каждый параметр
    // для каждого поля отдельный, то надо вычислять by по кол-ву полей
    final int maxBy = 999; // смотри SQLITE_LIMIT_VARIABLE_NUMBER

    int now = DateTime.now().millisecondsSinceEpoch;

    int veryStarted = now;
    int started = now;

    int fieldsCount = 1;
    int by = 100;

    /* CatContpos, update with Catalogue */
    if (key == 'CatContpos' || key == 'Catalogue' || key == 'All') {
      int catContposCount = data.catContpos.length;
      fieldsCount = CatContpos().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int catContposPages = (catContposCount ~/ by) + 1;

      List<dynamic> catContposQueriesPages = [];
      for (var i = 0; i < catContposPages; i++) {
        //Log.d(TAG, 'Update catContpos ${i + 1} / $catContposPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> catContpos = await CatContpos()
            .prepareTransactionQueries(data.catContpos, i * by, i * by + by);
        catContposQueriesPages.add(catContpos);
        //await CatContpos().transaction(catContpos);
      }
      await CatContpos().massTransaction(catContposQueriesPages);

      int loadedCatContpos = await CatContpos().getCount();
      print('CatContpos count $loadedCatContpos');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback(
          {'loadedCatContpos': '$loadedCatContpos/$catContposCount'});
      CompaniesManager.catContposLoaded = true;

      /* Catalogue */
      int catalogueCount = data.catalogue.length;
      fieldsCount = Catalogue().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int cataloguePages = (catalogueCount ~/ by) + 1;

      List<dynamic> catalogueQueriesPages = [];
      for (var i = 0; i < cataloguePages; i++) {
        //Log.d(TAG, 'Update catalogue ${i + 1} / $cataloguePages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> catalogue = await Catalogue()
            .prepareTransactionQueries(data.catalogue, i * by, i * by + by);
        catalogueQueriesPages.add(catalogue);
        //await Catalogue().transaction(catalogue);
      }
      await Catalogue().massTransaction(catalogueQueriesPages);

      int loadedCatalogue = await Catalogue().getCount();
      print('Catalogue count $loadedCatalogue');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedCatalogue': '$loadedCatalogue/$catalogueCount'});
      // Сразу отдаем как загрузили
      List<Catalogue> rubrics = await Catalogue.getFullCatalogue();
      setStateCallback({'rubrics': rubrics});
      CompaniesManager.catalogueLoaded = true;

      // Update key for next step
      key = 'Cats';
    }
    /* Cats */
    if (key == 'Cats' || key == 'All') {
      int catsCount = data.cats.length;
      fieldsCount = Cats().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int catsPages = (catsCount ~/ by) + 1;

      List<dynamic> catsQueriesPages = [];
      for (var i = 0; i < catsPages; i++) {
        //Log.d(TAG, 'Update cats ${i + 1} / $catsPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> cats = await Cats()
            .prepareTransactionQueries(data.cats, i * by, i * by + by);
        catsQueriesPages.add(cats);
        //await Cats().transaction(cats);
      }
      await Cats().massTransaction(catsQueriesPages);

      int loadedCats = await Cats().getCount();
      print('Cats count $loadedCats');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedCats': '$loadedCats/$catsCount'});
      CompaniesManager.catsLoaded = true;

      // Update key for next step
      key = 'Orgs';
    }
    /* Orgs */
    if (key == 'Orgs' || key == 'All') {
      int orgsCount = data.orgs.length;
      fieldsCount = Orgs().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int orgsPages = (orgsCount ~/ by) + 1;

      List<dynamic> orgsQueriesPages = [];
      for (var i = 0; i < orgsPages; i++) {
        //Log.d(TAG, 'Update orgs ${i + 1} / $orgsPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> orgs = await Orgs()
            .prepareTransactionQueries(data.orgs, i * by, i * by + by);
        orgsQueriesPages.add(orgs);
        //await Orgs().transaction(orgs);
      }
      await Orgs().massTransaction(orgsQueriesPages);

      int loadedOrgs = await Orgs().getCount();
      print('Orgs count $loadedOrgs');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedOrgs': '$loadedOrgs/$orgsCount'});
      CompaniesManager.orgsLoaded = true;

      // Update key for next step
      key = 'Branches';
    }
    /* Branches */
    if (key == 'Branches' || key == 'All') {
      int branchesCount = data.branches.length;
      fieldsCount = Branches().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int branchesPages = (branchesCount ~/ by) + 1;

      List<dynamic> branchesQueriesPages = [];
      for (var i = 0; i < branchesPages; i++) {
        //Log.d(TAG, 'Update branches ${i + 1} / $branchesPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> branches = await Branches()
            .prepareTransactionQueries(data.branches, i * by, i * by + by);
        branchesQueriesPages.add(branches);
        //await Branches().transaction(branches);
      }
      await Branches().massTransaction(branchesQueriesPages);

      int loadedBranches = await Branches().getCount();
      print('Branches count $loadedBranches');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedBranches': '$loadedBranches/$branchesCount'});
      CompaniesManager.branchesLoaded = true;

      // Update key for next step
      key = 'Phones';
    }
    /* Phones */
    if (key == 'Phones' || key == 'All') {
      int phonesCount = data.phones.length;
      fieldsCount = Phones().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int phonesPages = (phonesCount ~/ by) + 1;

      List<dynamic> phonesQueriesPages = [];
      for (var i = 0; i < phonesPages; i++) {
        //Log.d(TAG, 'Update phones ${i + 1} / $phonesPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> phones = await Phones()
            .prepareTransactionQueries(data.phones, i * by, i * by + by);
        phonesQueriesPages.add(phones);
        //await Phones().transaction(phones);
      }
      await Phones().massTransaction(phonesQueriesPages);

      int loadedPhones = await Phones().getCount();
      print('Phones count $loadedPhones');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedPhones': '$loadedPhones/$phonesCount'});
      CompaniesManager.phonesLoaded = true;

      // Update key for next step
      key = 'Addresses';
    }
    /* Addresses */
    if (key == 'Addresses' || key == 'All') {
      int addressesCount = data.addresses.length;
      fieldsCount = Addresses().toMap().keys.length;
      by = maxBy ~/ fieldsCount;
      int addressesPages = (addressesCount ~/ by) + 1;

      List<dynamic> addressesQueriesPages = [];
      for (var i = 0; i < addressesPages; i++) {
        //Log.d(TAG, 'Update addresses ${i + 1} / $addressesPages (${i * by} - ${i * by + by}), fieldsCount $fieldsCount');
        List<dynamic> addresses = await Addresses()
            .prepareTransactionQueries(data.addresses, i * by, i * by + by);
        addressesQueriesPages.add(addresses);
        //await Addresses().transaction(addresses);
      }
      await Addresses().massTransaction(addressesQueriesPages);

      int loadedAddresses = await Addresses().getCount();
      print('Addresses count $loadedAddresses');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedAddresses': '$loadedAddresses/$addressesCount'});
      CompaniesManager.addressesLoaded = true;
    }
    now = DateTime.now().millisecondsSinceEpoch;
    print('total elapsed ${now - veryStarted}');
  }

  Future<void> loadCompaniesUpdate({String key}) async {
    Future.delayed(Duration(milliseconds: 250), () async {
      CompaniesUpdate data = await CompaniesUpdate.parseUpdateFile();
      Log.d(TAG, 'Update data: $data');
      await saveData(data, key: key);
    });
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
