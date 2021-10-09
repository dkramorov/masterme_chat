import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/phones.dart';

class Orgs extends AbstractModel {
  final int id;
  final int rating;
  final int branches;
  final String name;
  final String resume;
  final int phones;
  final String logo;
  final String searchTerms;
  final int reg;

  List<Branches> branchesArr = [];
  List<Phones> phonesArr = [];

  static const TAG = 'Orgs';
  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'orgs';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Orgs.tableName;
  }

  String getLogoPath() {
    if (id == null || logo == null) {
      return null;
    }
    return DB_SERVER + DB_LOGO_PATH.replaceAll('COMPANY_ID', '$id') + logo;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rating': rating,
      'branches': branches,
      'name': name,
      'resume': resume,
      'phones': phones,
      'logo': logo,
      'searchTerms': searchTerms,
      'reg': reg,
    };
  }

  Orgs({
    this.id,
    this.rating,
    this.branches,
    this.name,
    this.resume,
    this.phones,
    this.logo,
    this.searchTerms,
    this.reg,
  });

  @override
  String toString() {
    return 'id: $id, rating: $rating, branches: $branches, ' +
        'name: $name, resume: $resume, ' +
        'phones: $phones, logo: $logo, ' +
        'searchTerms: $searchTerms, ' +
        'reg: $reg';
  }

  static List<Orgs> jsonFromList(List<dynamic> arr) {
    List<Orgs> result = [];
    arr.forEach((item) {
      result.add(Orgs.fromJson(item));
    });
    return result;
  }

  factory Orgs.fromJson(Map<String, dynamic> json) {
    return Orgs(
      id: json['id'] as int,
      rating: json['rating'] as int,
      branches: json['branches'] as int,
      name: json['name'] as String,
      resume: json['resume'] as String,
      phones: json['phones'] as int,
      logo: json['logo'] as String,
      searchTerms: json['search_terms'] as String,
      reg: json['reg'] as int,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Orgs toModel(Map<String, dynamic> dbItem) {
    return Orgs(
      id: dbItem['id'],
      rating: dbItem['rating'],
      branches: dbItem['branches'],
      name: dbItem['name'],
      resume: dbItem['resume'],
      phones: dbItem['phones'],
      logo: dbItem['logo'],
      searchTerms: dbItem['searchTerms'],
      reg: dbItem['reg'],
    );
  }

  static Future<List<Orgs>> getCategoryOrgs(int catId) async {
    final db = await openCompaniesDB();
    String fields = Orgs().toMap().keys.map((key) {
      return '$tableName.$key';
    }).join(', ');
    String query = 'SELECT $fields from $tableName' +
        ' INNER JOIN cats ON cats.clientId = orgs.id' +
        ' WHERE cats.catId = ?';
    // db.rawQuery('SELECT * FROM my_table WHERE name IN (?, ?, ?)', ['cat', 'dog', 'fish']);
    Log.d(TAG, query + ', $catId');
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [catId]);
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  static Future<Orgs> getOrg(int orgId) async {
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> orgs = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [orgId],
    );
    if (orgs.isEmpty) {
      return null;
    }
    return toModel(orgs[0]);
  }

  static Future<List<Orgs>> searchOrgs(String query,
      {int limit: 10, int offset: 0}) async {
    final db = await openCompaniesDB();

    String pattern = 'searchTerms LIKE ?';
    List<String> whereClause = [];
    List<dynamic> args = [];
    for (String word in query.split(' ')) {
      word = word.trim();
      if (word.length > 0) {
        args.add('%$word%');
        whereClause.add(pattern);
      }
    }
    if (args.isEmpty) {
      return List.empty();
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause.join(' AND '),
      whereArgs: args,
      limit: limit,
      offset: offset,
    );
    Log.d(TAG,
        'SEARCH $tableName: ${whereClause.toString()}, ${args.toString()}');
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  static Future<List<Orgs>> getOrgsByPhones(List<Phones> phones) async {
    final db = await openCompaniesDB();
    List<int> ids = [];

    for (Phones phone in phones) {
      if (phone.client == null) {
        continue;
      }
      ids.add(phone.client);
    }
    String idsOrgs = ids.join(', ');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id IN ($idsOrgs)',
    );

    return List.generate(maps.length, (i) {
      Orgs org = toModel(maps[i]);
      // Докидываем телефоны в компанию
      for (Phones phone in phones) {
        if (phone.client == org.id) {
          org.phonesArr.add(phone);
        }
      }
      return org;
    });
  }
}
