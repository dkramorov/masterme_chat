import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/log.dart';

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

  Key key;

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

  /* Перегоняем данные из базы в модельку */
  static ContactChatModel toModel(Map<String, dynamic> dbItem) {
    return ContactChatModel(
      id: dbItem['id'],
      login: dbItem['login'],
      name: dbItem['name'],
      avatar: dbItem['avatar'],
      status: dbItem['status'],
      parent: dbItem['parent'],
      time: dbItem['time'],
      msg: dbItem['msg'],
    );
  }

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

    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  /* Обновляем выборочные поля контакта */
  static Future<void> updateContact(int pk, Map<String, dynamic> values) async {
    if (pk == null) {
      Log.e('[ERROR]: updateContact', 'pk is null');
      return;
    }
    Log.d('updateContact pk=$pk', '${values.toString()}');
    final db = await openDB();
    int updated = await db.update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [pk],
    );
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
    return toModel(user);
  }
}
