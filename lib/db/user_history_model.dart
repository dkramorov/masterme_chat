import 'dart:collection';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/models/companies/orgs.dart';

class UserHistoryModel extends AbstractModel {
  static const String TAG = 'UserHistoryModel';

  int id; // null if we need new row
  String login;
  String time;
  int duration;
  String source; // от кого-то
  String dest; // кому мы наябываем
  String action; // outgoing/incoming call/chat
  int companyId; // Ид компании (т/к компании в другой базе)
  Orgs company; // Компанию заполняем из sql запроса

  static final String tableName = 'users_history';

  @override
  String getTableName() {
    return UserHistoryModel.tableName;
  }

  UserHistoryModel({
    this.id,
    this.login,
    this.time,
    this.duration,
    this.source,
    this.dest,
    this.action,
    this.companyId,
  });

  String getLogin() {
    return this.login.replaceAll('@$JABBER_SERVER', '');
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'time': time,
      'duration': duration,
      'source': source,
      'dest': dest,
      'action': action,
      'companyId': companyId,
    };
  }

  /* Перегоняем данные из базы в модельку */
  static UserHistoryModel toModel(Map<String, dynamic> dbItem) {
    return UserHistoryModel(
      id: dbItem['id'],
      login: dbItem['login'],
      time: dbItem['time'],
      duration: dbItem['duration'],
      source: dbItem['source'],
      dest: dbItem['dest'],
      action: dbItem['action'],
      companyId: dbItem['companyId'],
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, time: $time,' +
        ' duration: $duration, source: $source, dest: $dest, action: $action,' +
        'companyId: $companyId}';
  }

  static Future<List<UserHistoryModel>> getAllHistory(String login) async {
    final db = await openDB();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'login = ?',
      whereArgs: [login],
    );

    HashMap<int, Orgs> idsCompanies = HashMap();
    for (Map<String, dynamic> item in maps) {
      if (item['companyId'] != null && item['companyId'] != 0) {
        idsCompanies[item['companyId']] = null;
      }
    }

    if (idsCompanies.isNotEmpty) {
      await Orgs.getOrgsByIds(idsCompanies);
    }

    return List.generate(maps.length, (i) {
      UserHistoryModel historyModel = toModel(maps[i]);
      if (historyModel.companyId != null &&
          historyModel.companyId != 0 &&
          idsCompanies.containsKey(historyModel.companyId)) {
        historyModel.company = idsCompanies[historyModel.companyId];
      }
      return historyModel;
    });
  }
}
