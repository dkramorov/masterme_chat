import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/log.dart';

/* Пользователи чата в базе данных */
class UserChatModel extends AbstractModel {
  static const String TAG = 'UserChatModel';

  int id; // null if we need new row
  String login;
  String passwd;
  int lastLogin;

  static final String tableName = 'users_chat';

  @override
  String getTableName() {
    return UserChatModel.tableName;
  }

  UserChatModel({this.id, this.login, this.passwd, this.lastLogin});

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'passwd': passwd,
      'lastLogin': lastLogin,
    };
  }

  /* Перегоняем данные из базы в модельку */
  static UserChatModel toModel(Map<String, dynamic> dbItem) {
    return UserChatModel(
      id: dbItem['id'],
      login: dbItem['login'],
      passwd: dbItem['passwd'],
      lastLogin: dbItem['lastLogin'],
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, passwd: $passwd, lastLogin: $lastLogin}';
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

  // Сбросить всем флаг lastLogin
  static Future<void> clearLastLogin() async {
    final db = await openDB();
    final updated = await db.update(
      tableName,
      {'lastLogin': 0},
    );
    Log.w('$tableName', 'clearLastLogin = $updated');
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
    return UserChatModel(
      id: user['id'],
      login: user['login'],
      passwd: user['passwd'],
    );
  }

  static Future<List<UserChatModel>> getAllUsers(
      {int limit, int offset}) async {
    final db = await openDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  static Future<UserChatModel> getLastLoginUser() async {
    final db = await openDB();
    final List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: 'lastLogin = 1',
    );
    if (users.isNotEmpty) {
      return toModel(users[0]);
    }
    return null;
  }

  // Воткнуть пользователя в базу или обновить
  static Future<UserChatModel> insertLastLoginUser(String login, String passwd) async {
    await UserChatModel.clearLastLogin();
    String curLogin = login.replaceAll(RegExp('[^0-9]+'), '');
    UserChatModel user = await UserChatModel.getByLogin(curLogin);
    if (user == null) {
      user = UserChatModel(
        login: curLogin,
        passwd: passwd,
        lastLogin: 1,
      );
    } else {
      user.lastLogin = 1;
    }
    await user.insert2Db();
    return user;
  }
}
