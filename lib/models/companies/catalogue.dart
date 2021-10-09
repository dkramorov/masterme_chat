import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';

class Catalogue extends AbstractModel {
  final int id;
  final int count;
  final String searchTerms;
  final String name;

  static const TAG = 'Catalogue';
  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'catalogue';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Catalogue.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'count': count,
      'searchTerms': searchTerms,
      'name': name,
    };
  }

  Catalogue({
    this.id,
    this.count,
    this.searchTerms,
    this.name,
  });

  @override
  String toString() {
    return 'id: $id, count: $count, searchTerms: $searchTerms, ' +
        'name: $name';
  }

  static List<Catalogue> jsonFromList(List<dynamic> arr) {
    List<Catalogue> result = [];
    arr.forEach((item) {
      result.add(Catalogue.fromJson(item));
    });
    return result;
  }

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue(
      id: json['id'] as int,
      count: json['count'] as int,
      searchTerms: json['search_terms'] as String,
      name: json['name'] as String,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Catalogue toModel(Map<String, dynamic> dbItem) {
    return Catalogue(
      id: dbItem['id'],
      count: dbItem['count'],
      searchTerms: dbItem['searchTerms'],
      name: dbItem['name'],
    );
  }

  static Future<List<Catalogue>> getFullCatalogue({String sort = 'name'}) async {
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: sort,
    );
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  static Future<List<Catalogue>> searchCatalogue(String query,
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

}
