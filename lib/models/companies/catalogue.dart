import 'package:masterme_chat/db/database_singletone.dart';

class Catalogue extends AbstractModel {
  final int id;
  final int count;
  final String searchTerms;
  final String name;

  static final String tableName = 'catalogue';

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
      searchTerms: json['searchTerms'] as String,
      name: json['name'] as String,
    );
  }
}
