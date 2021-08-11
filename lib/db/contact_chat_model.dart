import 'database_singletone.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

/* Ростер (контакты) в базе данных */
class ContactChatModel extends AbstractModel {
  int id; // null if we need new row
  String login;
  String name;
  String avatar;
  String status;
  String parent; // UserChatModel login
  String time;
  String msg;

  xmpp.Buddy buddy;

  static final String tableName = 'contacts_chat';

  @override
  String getTableName() {
    return ContactChatModel.tableName;
  }

  ContactChatModel({id, login, name, avatar, status, parent, time, msg}) {
    this.id = id;
    this.login = login;
    this.name = name;
    this.avatar = avatar;
    this.status = status;
    this.parent = parent;
    this.time = time;
    this.msg = msg;

    xmpp.Jid jid = xmpp.Jid.fromFullJid(login);
    this.buddy = xmpp.Buddy(jid);
  }

  // Convert into a Map
  // The keys must correspond to the names of the
  // columns in the database
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'name': name,
      'avatar': avatar,
      'status': status,
      'parent': parent,
      'time': time,
      'msg': msg,
    };
  }

  // Implement toString to make it easier to see information
  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, name: $name, avatar: $avatar, status: $status, parent: $parent, time: $time, msg: $msg}';
  }

  // A method that retrieves contacts for parent user
  static Future<List<ContactChatModel>> getAllContacts(String parent) async {
    final db = await openDB();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'parent = ?',
      whereArgs: [parent],
    );

    // Convert the List<Map<String, dynamic> into a List<ContactChatModel>.
    return List.generate(maps.length, (i) {
      return ContactChatModel(
        id: maps[i]['id'],
        login: maps[i]['login'],
        name: maps[i]['name'],
        avatar: maps[i]['avatar'],
        status: maps[i]['status'],
        parent: maps[i]['parent'],
        time: maps[i]['time'],
        msg: maps[i]['msg'],
      );
    });
  }


  /* Получение сообщения по коду */
  static Future<ContactChatModel> getByLogin(String parent, String login) async {
    final db = await openDB();

    final List<Map<String, dynamic>> users = await db.query(
      tableName,
      where: 'parent = ? and login = ?',
      whereArgs: [parent, login],
    );

    if (users.isEmpty) {
      return null;
    }
    final Map<String, dynamic> user = users[0];
    // Convert the List<Map<String, dynamic> into a List<ContactChatModel>.
    return ContactChatModel(
      id: user['id'],
      login: user['login'],
      name: user['name'],
      avatar: user['avatar'],
      status: user['status'],
      parent: user['parent'],
      time: user['time'],
      msg: user['msg'],
    );
  }
}
