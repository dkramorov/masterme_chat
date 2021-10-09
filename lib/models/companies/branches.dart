import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/models/companies/addresses.dart';

class Branches extends AbstractModel {
  int id;
  String wtime;
  String searchTerms;
  String site;
  String addressAdd;
  int address;
  String name;
  int reg;
  int client;
  int position;
  String email;

  Addresses mapAddress;

  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'branches';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Branches.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wtime': wtime,
      'searchTerms': searchTerms,
      'site': site,
      'addressAdd': addressAdd,
      'address': address,
      'name': name,
      'reg': reg,
      'client': client,
      'position': position,
      'email': email,
    };
  }

  Branches({
    this.id,
    this.wtime,
    this.searchTerms,
    this.site,
    this.addressAdd,
    this.address,
    this.name,
    this.reg,
    this.client,
    this.position,
    this.email,
  });

  @override
  String toString() {
    return 'id: $id, wtime: $wtime, searchTerms: $searchTerms, ' +
        'site: $site, addressAdd: $addressAdd, ' +
        'address: $address, ' +
        'name: $name, reg: $reg, client: $client, ' +
        'position: $position, email: $email';
  }

  static List<Branches> jsonFromList(List<dynamic> arr) {
    List<Branches> result = [];
    arr.forEach((item) {
      result.add(Branches.fromJson(item));
    });
    return result;
  }

  factory Branches.fromJson(Map<String, dynamic> json) {
    return Branches(
      id: json['id'] as int,
      wtime: json['wtime'] as String,
      searchTerms: json['search_terms'] as String,
      site: json['site'] as String,
      addressAdd: json['address_add'] as String,
      address: json['address'] as int,
      name: json['name'] as String,
      reg: json['reg'] as int,
      client: json['client'] as int,
      position: json['position'] as int,
      email: json['email'] as String,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Branches toModel(Map<String, dynamic> dbItem) {
    return Branches(
      id: dbItem['id'],
      wtime: dbItem['wtime'],
      searchTerms: dbItem['searchTerms'],
      site: dbItem['site'],
      addressAdd: dbItem['addressAdd'],
      address: dbItem['address'],
      name: dbItem['name'],
      reg: dbItem['reg'],
      client: dbItem['client'],
      position: dbItem['position'],
      email: dbItem['email'],
    );
  }

  static Future<List<Branches>> getOrgBranches(int orgId) async {
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> branches = await db.query(
      tableName,
      where: 'client = ?',
      whereArgs: [orgId],
    );
    return List.generate(branches.length, (i) {
      return toModel(branches[i]);
    });
  }
}