import 'dart:io';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/models/comanies_update.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';

class CompaniesManager {
  static const TAG = 'CompaniesManager';
  static final CompaniesManager _singleton = CompaniesManager._internal();
  CompaniesManager._internal();

  factory CompaniesManager() {
    return _singleton;
  }

  static bool addressesLoaded = false;
  static bool branchesLoaded = false;
  static bool catContposLoaded = false;
  static bool catalogueLoaded = false;
  static bool catsLoaded = false;
  static bool orgsLoaded = false;
  static bool phonesLoaded = false;

  static showLoaded() {
    print('addressesLoaded, $addressesLoaded');
    print('branchesLoaded, $branchesLoaded');
    print('catContposLoaded, $catContposLoaded');
    print('catalogueLoaded, $catalogueLoaded');
    print('catsLoaded, $catsLoaded');
    print('orgsLoaded, $orgsLoaded');
    print('phonesLoaded, $phonesLoaded');
  }

  static bool allLoaded() {
    if (!addressesLoaded ||
        !branchesLoaded ||
        !catContposLoaded ||
        !catalogueLoaded ||
        !catsLoaded ||
        !orgsLoaded ||
        !phonesLoaded) {
      showLoaded();
      return false;
    }
    return true;
  }
}
