import 'dart:async';
import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/models/comanies_update.dart';
import 'package:masterme_chat/models/companies/addresses.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/cat_contpos.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/models/companies/cats.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/companies_manager.dart';

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

  bool allLoaded = false;

  CompaniesScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    checkState();

    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  Future<void> loadCatalogue() async {
    List<Catalogue> rubrics = await Catalogue.getFullCatalogue();
    if (rubrics.isEmpty) {
      await loadCompaniesUpdate(key: 'Catalogue');
    } else {
      setStateCallback({'rubrics': rubrics});

      if (CompaniesManager.allLoaded()){
        return;
      }

      /* Проверяем количество в остальных таблицах */
      CompaniesUpate data = await CompaniesUpate.parseUpdateFile();
      Log.d(TAG, 'Check other data: $data');

      if (!CompaniesManager.catContposLoaded) {
        int catContposCount = await CatContpos().getCount();
        if (catContposCount < data.catContpos.length) {
          await saveData(data, key: 'CatContpos');
          return;
        } else {
          CompaniesManager.catContposLoaded = true;
        }
      }

      if (!CompaniesManager.catalogueLoaded) {
        int catalogueCount = await Catalogue().getCount();
        if (catalogueCount < data.catalogue.length) {
          await saveData(data, key: 'Catalogue');
          return;
        } else {
          CompaniesManager.catalogueLoaded = true;
        }
      }

      if (!CompaniesManager.catsLoaded) {
        int catsCount = await Cats().getCount();
        if (catsCount < data.cats.length) {
          await saveData(data, key: 'Cats');
          return;
        } else {
          CompaniesManager.catsLoaded = true;
        }
      }

      if (!CompaniesManager.orgsLoaded) {
        int orgsCount = await Orgs().getCount();
        if (orgsCount < data.orgs.length) {
          await saveData(data, key: 'Orgs');
          return;
        } else {
          CompaniesManager.orgsLoaded = true;
        }
      }

      if (!CompaniesManager.branchesLoaded) {
        int branchesCount = await Branches().getCount();
        if (branchesCount < data.branches.length) {
          await saveData(data, key: 'Branches');
          return;
        } else {
          CompaniesManager.branchesLoaded = true;
        }
      }

      if (!CompaniesManager.phonesLoaded) {
        int phonesCount = await Phones().getCount();
        if (phonesCount < data.phones.length) {
          await saveData(data, key: 'Phones');
          return;
        } else {
          CompaniesManager.phonesLoaded = true;
        }
      }

      if (!CompaniesManager.addressesLoaded) {
        int addressesCount = await Addresses().getCount();
        if (addressesCount < data.addresses.length) {
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
  Future<void> saveData(CompaniesUpate data, {String key}) async {
    final int by = 100;

    int now = DateTime.now().millisecondsSinceEpoch;
    int started = now;

    /* CatContpos, update with Catalogue */
    if (key == 'CatContpos' || key == 'Catalogue' || key == 'All') {
      int catContposCount = data.catContpos.length;
      int catContposPages = (catContposCount ~/ by) + 1;
      for (var i = 0; i < catContposPages; i++) {
        Log.d(TAG,
            'Update catContpos ${i + 1} / $catContposPages (${i * by} - ${i * by + by})');
        List<dynamic> catContpos = await CatContpos()
            .prepareTransactionQueries(data.catContpos, i * by, i * by + by);
        await CatContpos().transaction(catContpos);
      }
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
      int cataloguePages = (catalogueCount ~/ by) + 1;
      for (var i = 0; i < cataloguePages; i++) {
        Log.d(TAG,
            'Update catalogue ${i + 1} / $cataloguePages (${i * by} - ${i * by + by})');
        List<dynamic> catalogue = await Catalogue()
            .prepareTransactionQueries(data.catalogue, i * by, i * by + by);
        await Catalogue().transaction(catalogue);
      }
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
      int catsPages = (catsCount ~/ by) + 1;
      for (var i = 0; i < catsPages; i++) {
        Log.d(TAG,
            'Update cats ${i + 1} / $catsPages (${i * by} - ${i * by + by})');
        List<dynamic> cats = await Cats()
            .prepareTransactionQueries(data.cats, i * by, i * by + by);
        await Cats().transaction(cats);
      }
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
      int orgsPages = (orgsCount ~/ by) + 1;
      for (var i = 0; i < orgsPages; i++) {
        Log.d(TAG,
            'Update orgs ${i + 1} / $orgsPages (${i * by} - ${i * by + by})');
        List<dynamic> orgs = await Orgs()
            .prepareTransactionQueries(data.orgs, i * by, i * by + by);
        await Orgs().transaction(orgs);
      }
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
      int branchesPages = (branchesCount ~/ by) + 1;
      /* Branches */
      for (var i = 0; i < branchesPages; i++) {
        Log.d(TAG,
            'Update branches ${i + 1} / $branchesPages (${i * by} - ${i * by + by})');
        List<dynamic> branches = await Branches()
            .prepareTransactionQueries(data.branches, i * by, i * by + by);
        await Branches().transaction(branches);
      }
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
      int phonesPages = (phonesCount ~/ by) + 1;
      for (var i = 0; i < phonesPages; i++) {
        Log.d(TAG,
            'Update phones ${i + 1} / $phonesPages (${i * by} - ${i * by + by})');
        List<dynamic> phones = await Phones()
            .prepareTransactionQueries(data.phones, i * by, i * by + by);
        await Phones().transaction(phones);
      }
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
      int addressesPages = (addressesCount ~/ by) + 1;
      for (var i = 0; i < addressesPages; i++) {
        Log.d(TAG,
            'Update addresses ${i + 1} / $addressesPages (${i * by} - ${i * by + by})');
        List<dynamic> addresses = await Addresses()
            .prepareTransactionQueries(data.addresses, i * by, i * by + by);
        await Addresses().transaction(addresses);
      }
      int loadedAddresses = await Addresses().getCount();
      print('Addresses count $loadedAddresses');
      now = DateTime.now().millisecondsSinceEpoch;
      print('elapsed ${now - started}');
      started = now;
      setStateCallback({'loadedAddresses': '$loadedAddresses/$addressesCount'});
      CompaniesManager.addressesLoaded = true;
    }
  }

  Future<void> loadCompaniesUpdate({String key}) async {
    Future.delayed(Duration(milliseconds: 250), () async {
      CompaniesUpate data = await CompaniesUpate.parseUpdateFile();
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
