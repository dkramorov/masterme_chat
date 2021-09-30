import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:masterme_chat/models/companies/addresses.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/cat_contpos.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/models/companies/cats.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';

class CompaniesUpate {
  static const TAG = 'CompaniesUpate';
  static const updateFName = 'companies_db_helper.json';

  final List<Branches> branches;
  final List<Addresses> addresses;
  final List<Phones> phones;
  final List<Catalogue> catalogue;
  final List<Cats> cats;
  final List<Orgs> orgs;
  final List<CatContpos> catContpos;

  CompaniesUpate({
    this.branches,
    this.addresses,
    this.phones,
    this.catalogue,
    this.cats,
    this.orgs,
    this.catContpos,
  });

  @override
  String toString() {
    final int branchesLen = branches != null ? branches.length : 0;
    final int addressesLen = addresses != null ? addresses.length : 0;
    final int phonesLen = phones != null ? phones.length : 0;
    final int catalogueLen = catalogue != null ? catalogue.length : 0;
    final int catsLen = cats != null ? cats.length : 0;
    final int orgsLen = orgs != null ? orgs.length : 0;
    final int catContposLen = catContpos != null ? catContpos.length : 0;

    return 'branches: $branchesLen, addresses: $addressesLen, ' +
        'phones: $phonesLen, catalogue: $catalogueLen, ' +
        'cats: $catsLen, orgs: $orgsLen, ' +
        'catContpos: $catContposLen';
  }

  factory CompaniesUpate.fromJson(Map<String, dynamic> json) {
    return CompaniesUpate(
      branches: Branches.jsonFromList(json['branches'] as List<dynamic>),
      addresses: Addresses.jsonFromList(json['addresses'] as List<dynamic>),
      phones: Phones.jsonFromList(json['phones'] as List<dynamic>),
      catalogue: Catalogue.jsonFromList(json['catalogue'] as List<dynamic>),
      cats: Cats.jsonFromList(json['cats'] as List<dynamic>),
      orgs: Orgs.jsonFromList(json['orgs'] as List<dynamic>),
      catContpos: CatContpos.jsonFromList(json['cat_contpos'] as List<dynamic>),
    );
  }

  /* Сохранение всего говнища в базу */
  static Future<void> saveData(CompaniesUpate data) async {
    List<dynamic> branches =
        await Branches().prepareTransactionQueries(data.branches, 0, 100);
    Branches().transaction(branches);

/*
    List<dynamic> addresses = await Addresses().prepareTransactionQueries(data.addresses);
    List<dynamic> phones = await Phones().prepareTransactionQueries(data.phones);
    List<dynamic> catalogue = await Catalogue().prepareTransactionQueries(data.catalogue);
    List<dynamic> cats = await Cats().prepareTransactionQueries(data.cats);
    List<dynamic> orgs = await Orgs().prepareTransactionQueries(data.orgs);
    List<dynamic> catContpos = await CatContpos().prepareTransactionQueries(data.catContpos);
    Branches().transaction(branches);
    Addresses().transaction(addresses);
    Phones().transaction(phones);
    Catalogue().transaction(catalogue);
    Cats().transaction(cats);
    Orgs().transaction(orgs);
    CatContpos().transaction(catContpos);

 */
  }

  static CompaniesUpate parseResponse(String responseBody) {
    //final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    //return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
    final parsed = jsonDecode(responseBody);
    return CompaniesUpate.fromJson(parsed);
  }

  /* Обрабатываем файл, который только что загрузился и
     мы получили путь до него, либо если null,
     тогда пробуем найти в папке его
  */
  static Future<CompaniesUpate> parseUpdateFile() async {
    final String destFolder = await SaveNetworkFile.makeAppFolder();
    final updateFilePath = destFolder + '/' + updateFName;
    Log.d(TAG, 'Using exists file $updateFilePath');

    File updateFile = File(updateFilePath);
    if (!updateFile.existsSync()) {
      Log.d(TAG, '[ERROR]: file not found ${updateFile.path}');
      await downloadUpdate();
    }
    String content = await updateFile.readAsString();
    return parseResponse(content);
  }

  static Future<void> downloadUpdate() async {
    final url = '$DB_SERVER$DB_UPDATE_ENDPOINT';
    Log.d(TAG, url);
    final String destFolder = await SaveNetworkFile.makeAppFolder();
    final fileName = url.split('/').last;
    final File dest = File(destFolder + '/' + updateFName);
    Dio dio = new Dio();
    await dio.download(
      url,
      dest.path,
    );
    Log.d(TAG, 'update file downloaded ${dest.path}');
  }
}
