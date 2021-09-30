import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';

class UserHistoryModel extends AbstractModel {
  static const String TAG = 'UserHistoryModel';

  int id; // null if we need new row
  String login;
  String time;
  int duration;
  String source; // от кого-то
  String dest; // кому мы наябываем
  String action; // outgoing/incoming call/chat

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
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, time: $time,' +
        ' duration: $duration, source: $source, dest: $dest, action: $action}';
  }

  static Future<List<UserHistoryModel>> getAllHistory(String login) async {
    final db = await openDB();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'login = ?',
      whereArgs: [login],
    );

    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

}
