import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';

/* Пользователи чата в базе данных */
class UserChatModel extends AbstractModel {
  static const String TAG = 'UserChatModel';

  int id; // null if we need new row
  String login;
  String passwd;

  static final String tableName = 'users_chat';

  @override
  String getTableName() {
    return UserChatModel.tableName;
  }

  UserChatModel({this.id, this.login, this.passwd});

  // Convert into a Map
  // The keys must correspond to the names of the
  // columns in the database
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'passwd': passwd,
    };
  }

  // Implement toString to make it easier to see information
  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, passwd: $passwd}';
  }

  static Future<void> dropByLogin(String login) async {
    final db = await openDB();
    final dropped = await db.delete(
      tableName,
      where: 'login = ?',
      whereArgs: [login],
    );
    Log.w('$tableName', 'dropByLogin = $dropped');
  }

  static Future<UserChatModel> getByLogin(String userLogin) async {
    final db = await openDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'login = ?',
      whereArgs: [userLogin],
    );

    if (maps.isEmpty) {
      return null;
    }
    final Map<String, dynamic> user = maps[0];
    // Convert the List<Map<String, dynamic> into a List<UserChatModel>.
    return UserChatModel(
      id: user['id'],
      login: user['login'],
      passwd: user['passwd'],
    );
  }

  // A method that retrieves all from the settings table.
  static Future<List<UserChatModel>> getAllUsers(
      {int limit, int offset}) async {
    // Get a reference to the database.
    final db = await openDB();

    // Query the table for all
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      limit: limit,
      offset: offset,
    );

    // Convert the List<Map<String, dynamic> into a List<SettingsModel>.
    return List.generate(maps.length, (i) {
      return UserChatModel(
        id: maps[i]['id'],
        login: maps[i]['login'],
        passwd: maps[i]['passwd'],
      );
    });
  }
}
