import 'dart:io';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';

import 'database_singletone.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

/* Ростер (контакты) в базе данных */
class ContactChatModel extends AbstractModel {
  int id; // null if we need new row
  String login;
  String name;
  String avatar;
  String avatarUrl;
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

  ContactChatModel(
      {id, login, name, avatar, avatarUrl, status, parent, time, msg}) {
    this.id = id;
    this.login = login;
    this.name = name;
    this.avatar = avatar;
    this.avatarUrl = avatarUrl;
    this.status = status;
    this.parent = parent;
    this.time = time;
    this.msg = msg;

    xmpp.Jid jid = xmpp.Jid.fromFullJid(login);
    this.buddy = xmpp.Buddy(jid);
  }

  String getName() {
    if (this.name != null && this.name != '') {
      return this.name;
    }
    if (this.login.startsWith('89')) {
      return phoneMaskHelper(this.login);
    }
    return this.login;
  }

  Widget buildAvatar() {
    String pic = this.avatar;
    if (pic == null || pic == '' || !File(pic).existsSync()) {
      pic = DEFAULT_AVATAR;
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.transparent,
      //backgroundImage: AssetImage(pic),
      backgroundImage:
          pic == DEFAULT_AVATAR ? AssetImage(pic) : FileImage(File(pic)),
    );
  }

  Future<String> getAvatar({bool withDownload = false}) async {
    if (this.avatar != null && this.avatar != '') {
      if (!await File(this.avatar).exists()) {
        if (withDownload) {
          dowloadAvatar();
        }
        return DEFAULT_AVATAR;
      }
      return this.avatar;
    }
    return DEFAULT_AVATAR;
  }

  /* Загружаем аватарку если ссыль есть */
  Future<void> dowloadAvatar() async {
    ContactChatModel self = this;
    if (self.avatarUrl != null && self.avatarUrl.startsWith('http')) {
      SaveNetworkFile.getFileFromNetwork(self.avatarUrl).then((avatar) {
        this.updatePartial(self.id, {
          'avatarUrl': self.avatarUrl,
          'avatar': avatar.path,
        });
        self.avatar = avatar.path;
        self.key = UniqueKey();
      });
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'name': name,
      'avatar': avatar,
      'avatarUrl': avatarUrl,
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
      avatarUrl: dbItem['avatarUrl'],
      status: dbItem['status'],
      parent: dbItem['parent'],
      time: dbItem['time'],
      msg: dbItem['msg'],
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, name: $name, ' +
        'avatar: $avatar, avatarUrl: $avatarUrl, status: $status, ' +
        'parent: $parent, time: $time, msg: $msg}';
  }

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

  /* Получение сообщения по коду */
  static Future<ContactChatModel> getByLogin(
      String parent, String login) async {
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
