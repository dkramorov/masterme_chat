import 'database_singletone.dart';

/* Сообщение - черновик в базе данных */
class ChatDraftModel extends AbstractModel {
  int id;
  String login;
  String tuser;
  String msg; // сообщение

  static final String tableName = 'chat_draft';

  @override
  String getTableName() {
    return ChatDraftModel.tableName;
  }

  ChatDraftModel({
    this.id,
    this.login,
    this.tuser,
    this.msg,
  });

  // Convert into a Map
  // The keys must correspond to the names of the
  // columns in the database
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'tuser': tuser,
      'msg': msg,
    };
  }

  // Implement toString to make it easier to see information
  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, tuser: $tuser, msg: $msg}';
  }

  /* Очистить черновик */
  static Future<void> dropDraft(String login, String tuser) async {
    if (login == null || tuser == null) {
      return;
    }
    final db = await openDB();
    db.delete(
      tableName,
      where: 'login = ? and tuser = ?',
      whereArgs: [login, tuser],
    );
  }

  /* Записать черновик */
  static Future<void> setDraft(String login, String tuser, String msg) async {
    if (login == null || tuser == null) {
      return;
    }
    final draft = ChatDraftModel(login: login, tuser: tuser, msg: msg);
    draft.insert2Db();
  }

  /* Получение сообщения по логину UserChatModel */
  static Future<ChatDraftModel> getDraft(String login, String tuser) async {
    // Get a reference to the database.
    final db = await openDB();

    // Query the table for all
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'login = ? and tuser = ?',
      // Pass id as a whereArg to prevent SQL injection.
      whereArgs: [login, tuser],
    );

    if (maps.isEmpty) {
      return null;
    }
    final Map<String, dynamic> draft = maps[0];
    // Convert the List<Map<String, dynamic> into a List<ChatMessageModel>.
    return ChatDraftModel(
      id: draft['id'],
      login: draft['login'],
      tuser: draft['tuser'],
      msg: draft['msg'],
    );
  }
}
