import 'package:masterme_chat/db/database_singletone.dart';

class Cats extends AbstractModel {
  final int id;
  final int catId;
  final int clientId;

  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'cats';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Cats.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'catId': catId,
      'clientId': clientId,
    };
  }

  Cats({
    this.id,
    this.catId,
    this.clientId,
  });

  @override
  String toString() {
    return 'catId: $catId, id: $id, ' + 'clientId: $clientId';
  }

  static List<Cats> jsonFromList(List<dynamic> arr) {
    List<Cats> result = [];
    arr.forEach((item) {
      result.add(Cats.fromJson(item));
    });
    return result;
  }

  factory Cats.fromJson(Map<String, dynamic> json) {
    return Cats(
      id: json['id'] as int,
      catId: json['cat_id'] as int,
      clientId: json['client_id'] as int,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Cats toModel(Map<String, dynamic> dbItem) {
    return Cats(
      id: dbItem['id'],
      catId: dbItem['catId'],
      clientId: dbItem['clientId'],
    );
  }

  static Future<List<Cats>> getOrgCats(int orgId) async {
    /* Получение связок с рубриками по айди фирмы */
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> cats = await db.query(
      Cats.tableName,
      where: 'clientId = ?',
      whereArgs: [orgId],
    );
    return List.generate(cats.length, (i) {
      return toModel(cats[i]);
    });
  }

}
