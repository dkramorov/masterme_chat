import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';

class Phones extends AbstractModel {
  int id;
  String digits;
  String comment;
  int prefix;
  int client;
  int whata;
  int branch;
  int position;
  String searchTerms;
  String number;

  String formattedPhone = '';

  static const TAG = 'Phones';
  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'phones';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Phones.tableName;
  }

  Phones({
    id,
    digits,
    comment,
    prefix,
    client,
    whata,
    branch,
    position,
    searchTerms,
    number,
  }) {
    this.id = id;
    this.digits = digits;
    this.comment = comment;
    this.prefix = prefix;
    this.client = client;
    this.whata = whata;
    this.branch = branch;
    this.position = position;
    this.searchTerms = searchTerms;
    this.number = number;
    this.formattedPhone = defizPhone(buildPhoneString());
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

  String getWhataDisplay(digit) {
    if (digit == 1) {
      return 'тел';
    }
    if (digit == 2) {
      return 'факс';
    }
    if (digit == 3) {
      return 'тел/факс';
    }
    if (digit == 4) {
      return 'моб';
    }
    return '';
  }

  String buildPhoneString() {
    String result = '';
    if (this.prefix != null) {
      result += '${this.prefix}';
    }
    if (this.digits != null) {
      result += '${this.digits}';
    }
    return result;
  }

  static String prefixPhone(String phoneStr) {
    if (phoneStr.length == 6) {
      phoneStr = '73952$phoneStr';
    } else if (phoneStr.length == 10) {
      phoneStr = '7$phoneStr';
    }
    return phoneStr;
  }

  static String defizPhone(String phone) {
    phone = phone.replaceAll(RegExp('[^0-9]+'), '');
    phone = prefixPhone(phone);
    int phoneLen = phone.length;
    if (phoneLen == 5 || phoneLen == 6) {
      phone = '${phone.substring(0, 3)}-${phone.substring(3, phoneLen)}';
    } else if (phoneLen == 7) {
      phone =
          '${phone.substring(0, 1)}-${phone.substring(1, 4)}-${phone.substring(4, phoneLen)}';
    } else if (phoneLen == 10) {
      if (phone.startsWith('9')) {
        // сотовые
        phone =
            '(${phone.substring(0, 3)}) ${phone.substring(3, 4)}-${phone.substring(4, 7)}-${phone.substring(7, phoneLen)}';
      } else {
        // городские
        phone =
            '(${phone.substring(0, 4)}) ${phone.substring(4, 7)}-${phone.substring(7, phoneLen)}';
      }
    } else if (phoneLen == 11) {
      if (phone[1] == '9') {
        // сотовые
        phone = '${phone.substring(0, 1)} (${phone.substring(1, 4)})' +
            ' ${phone.substring(4, 5)}-${phone.substring(5, 8)}-${phone.substring(8, phoneLen)}';
      } else {
        // городские
        phone = '${phone.substring(0, 1)} (${phone.substring(1, 5)})' +
            ' ${phone.substring(5, 8)}-${phone.substring(8, phoneLen)}';
      }
      if (phone.startsWith('7')) {
        phone = '+${phone}';
      }
    }
    return phone;
  }

  @override
  String toString() {
    /*
    return 'id: $id, digits: $digits, comment: $comment, ' +
        'prefix: $prefix, client: $client, ' +
        'whata: $whata, branch: $branch, ' +
        'position: $position, searchTerms: $searchTerms, ' +
        'number: $number';
    */
    String result = '';
    if (number != null && number != '') {
      result += getWhataDisplay(whata);
      if (prefix != null && prefix != 0) {
        result += '(${prefix.toString()}) ';
      }
      result += number;
      return result;
    }
    return getWhataDisplay(whata) + digits;
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
      prefix: AbstractModel.getInt(json['prefix']),
      client: json['client'] as int,
      whata: AbstractModel.getInt(json['whata']),
      branch: json['branch'] as int,
      position: json['position'] as int,
      searchTerms: json['search_terms'] as String,
      number: json['number'] as String,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Phones toModel(Map<String, dynamic> dbItem) {
    return Phones(
      id: dbItem['id'],
      digits: dbItem['digits'],
      comment: dbItem['comment'],
      prefix: dbItem['prefix'],
      client: dbItem['client'],
      whata: dbItem['whata'],
      branch: dbItem['branch'],
      position: dbItem['position'],
      searchTerms: dbItem['searchTerms'],
      number: dbItem['number'],
    );
  }

  static Future<List<Phones>> getOrgPhones(int orgId) async {
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> phones = await db.query(
      tableName,
      where: 'client = ?',
      whereArgs: [orgId],
    );
    return List.generate(phones.length, (i) {
      return toModel(phones[i]);
    });
  }

  static Future<List<Phones>> searchPhones(String query,
      {int limit: 10, int offset: 0}) async {
    final db = await openCompaniesDB();

    String pattern = 'searchTerms LIKE ?';
    List<String> whereClause = [];
    List<dynamic> args = [];
    for (String word in query.split(' ')) {
      word = word.replaceAll(RegExp('[^0-9]+'), '');;
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
