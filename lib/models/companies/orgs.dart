import 'package:masterme_chat/db/database_singletone.dart';

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

  static final String tableName = 'orgs';

  @override
  String getTableName() {
    return Orgs.tableName;
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
      searchTerms: json['searchTerms'] as String,
      reg: json['reg'] as int,
    );
  }
}
