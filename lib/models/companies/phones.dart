import 'package:masterme_chat/db/database_singletone.dart';

class Phones extends AbstractModel {
  final int id;
  final String digits;
  final String comment;
  final String prefix;
  final int client;
  final int whata;
  final int branch;
  final int position;
  final String searchTerms;
  final String number;

  static final String tableName = 'phones';

  @override
  String getTableName() {
    return Phones.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'digits': digits,
      'comment': comment,
      'prefix': prefix,
      'client': client,
      'whata': whata,
      'branch': branch,
      'position': position,
      'searchTerms': searchTerms,
      'number': number,
    };
  }

  Phones({
    this.id,
    this.digits,
    this.comment,
    this.prefix,
    this.client,
    this.whata,
    this.branch,
    this.position,
    this.searchTerms,
    this.number,
  });

  String getWhataDisplay(digit) {
    if (digit == 1) {
      return 'тел';
    }
    if (digit == 2) {
      return 'факс';
    }
    if (digit == 3) {
      return 'тел./факс';
    }
    if (digit == 4) {
      return 'моб.';
    }
    return '';
  }

  @override
  String toString() {
    return 'id: $id, digits: $digits, comment: $comment, ' +
        'prefix: $prefix, client: $client, ' +
        'whata: $whata, branch: $branch, ' +
        'position: $position, searchTerms: $searchTerms, ' +
        'number: $number';
  }

  static List<Phones> jsonFromList(List<dynamic> arr) {
    List<Phones> result = [];
    arr.forEach((item) {
      result.add(Phones.fromJson(item));
    });
    return result;
  }

  factory Phones.fromJson(Map<String, dynamic> json) {
    return Phones(
      id: json['id'] as int,
      digits: json['digits'] as String,
      comment: json['comment'] as String,
      prefix: json['prefix'] as String,
      client: json['client'] as int,
      whata: AbstractModel.getInt(json['whata']),
      branch: json['branch'] as int,
      position: json['position'] as int,
      searchTerms: json['searchTerms'] as String,
      number: json['number'] as String,
    );
  }
}
