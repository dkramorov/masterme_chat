import 'package:masterme_chat/db/database_singletone.dart';

class CatContpos extends AbstractModel {
  final int id;
  final int position;
  final int catId;
  final int clientId;

  static final String tableName = 'cat_contpos';

  @override
  String getTableName() {
    return CatContpos.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position,
      'catId': catId,
      'clientId': clientId,
    };
  }

  CatContpos({
    this.id,
    this.position,
    this.catId,
    this.clientId,
  });

  @override
  String toString() {
    return 'id: $id, position: $position, catId: $catId, ' +
        'clientId: $clientId';
  }

  static List<CatContpos> jsonFromList(List<dynamic> arr) {
    List<CatContpos> result = [];
    arr.forEach((item) {
      result.add(CatContpos.fromJson(item));
    });
    return result;
  }

  factory CatContpos.fromJson(Map<String, dynamic> json) {
    return CatContpos(
      id: json['id'] as int,
      position: json['position'] as int,
      catId: json['catId'] as int,
      clientId: json['clientId'] as int,
    );
  }
}
