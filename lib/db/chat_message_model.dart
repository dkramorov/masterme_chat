import 'dart:io';
import 'package:flutter/material.dart';
import 'package:masterme_chat/widgets/chat/message_widget.dart';

import 'database_singletone.dart';

/* Сообщения в базе данных */

//   SendStates     0       1       2       3
enum SendStates { none, pending, sent, delivered }
// pending ставим только для повторной отправки, если есть связь

class ChatMessageModel extends AbstractModel {
  static const String TAG = 'ChatMessageModel';

  int id; // null if we need new row
  String fuser;
  String tuser;
  int code; // ид сообщения
  String type; // типа сообщения (группа)
  String parent; // логин аккаунта из UserChatModel
  String time; // время сообщения
  String msg; // сообщение
  String url; // ссылка на медиа
  String urlType; // типа медиа
  String filePath; // путь к файлу, расположенному локально
  int sendState; // Состояние отправки сообщения

  static final String tableName = 'chat_messages';

  @override
  String getTableName() {
    return ChatMessageModel.tableName;
  }

  ChatMessageModel({
    this.id,
    this.fuser,
    this.tuser,
    this.code,
    this.type,
    this.parent,
    this.time,
    this.msg,
    this.url,
    this.urlType,
    this.filePath,
    this.sendState,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fuser': fuser,
      'tuser': tuser,
      'code': code,
      'type': type,
      'parent': parent,
      'time': time,
      'msg': msg,
      'url': url,
      'urlType': urlType,
      'filePath': filePath,
      'sendState': sendState,
    };
  }

  /* Перегоняем данные из базы в модельку */
  static ChatMessageModel toModel(Map<String, dynamic> dbItem) {
    return ChatMessageModel(
      id: dbItem['id'],
      fuser: dbItem['fuser'],
      tuser: dbItem['tuser'],
      code: dbItem['code'],
      type: dbItem['type'],
      parent: dbItem['parent'],
      time: dbItem['time'],
      msg: dbItem['msg'],
      url: dbItem['url'],
      urlType: dbItem['urlType'],
      filePath: dbItem['filePath'],
      sendState: dbItem['sendState'],
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, sendState: $sendState, from: $fuser, to: $tuser, code: $code,' +
        ' type: $type, parent: $parent, time: $time, msg: $msg,' +
        ' url: $url, urlType: $urlType, filePath: $filePath}';
  }

  /* Получение сообщений по логину UserChatModel */
  static Future<List<ChatMessageModel>> getByParent(
    String parent,
    String fuser,
    String tuser, {
    String orderBy,
    int limit,
    int offset,
  }) async {
    final db = await openDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where:
          'parent = ? and (fuser = ? OR tuser = ?) and (fuser = ? OR tuser = ?)' +
              'and code not NULL',
      whereArgs: [parent, fuser, fuser, tuser, tuser],
      orderBy: orderBy, //'code DESC'
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  /* Получение неотправленных сообщений (code=NULL)
     по логину UserChatModel
  */
  static Future<List<ChatMessageModel>> getByParentNullSent(
    String parent,
    String fuser,
    String tuser,
  ) async {
    final db = await openDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'parent = ? and fuser = ? and tuser = ? and code is NULL',
      whereArgs: [parent, fuser, tuser],
    );
    return List.generate(maps.length, (i) {
      return toModel(maps[i]);
    });
  }

  /* Получение всех сообщений */
  static Future<List<ChatMessageModel>> getAllMessages({
    String parent,
  }) async {
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

  /* Получение сообщения аналога по коду */
  static Future<ChatMessageModel> getAnalogByCode({
    String parent,
    int code,
    String tuser,
    String fuser,
  }) async {
    final db = await openDB();
    final String where = 'parent = ? and code = ? and tuser = ? and fuser = ?';
    final List<dynamic> args = [parent, code, tuser, fuser];
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: args,
    );
    if (maps.isEmpty) {
      //Log.d('$tableName getAnalog', 'NOT FOUND: $where, $args');
      return null;
    }
    return toModel(maps[0]);
  }

  /* Получение сообщения аналога по pk */
  static Future<ChatMessageModel> getAnalogByPk({
    String parent,
    int pk,
    String tuser,
    String fuser,
  }) async {
    final db = await openDB();
    final String where =
        'parent = ? and id = ? AND code IS NULL and tuser = ? and fuser = ?';
    final List<dynamic> args = [parent, pk, tuser, fuser];
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: args,
    );
    if (maps.isEmpty) {
      //Log.d('$tableName getAnalog', 'NOT FOUND: $where, $args');
      return null;
    }
    return toModel(maps[0]);
  }

  /* Получение сообщения аналога по коду или pk */
  static Future<ChatMessageModel> getAnalog({
    String parent,
    int code,
    int pk,
    String tuser,
    String fuser,
  }) async {
    final db = await openDB();
    // Сначала ищем по коду
    final ChatMessageModel result = await getAnalogByCode(
      parent: parent,
      code: code,
      tuser: tuser,
      fuser: fuser,
    );
    if (result != null) {
      return result;
    }
    // Если нет, ищем по ид
    return getAnalogByPk(
      parent: parent,
      pk: pk,
      tuser: tuser,
      fuser: fuser,
    );
  }

  /* Конвертим ChatMessageModel сообщение в виджет Message */
  static Message convert2Message(
      ChatMessageModel chatMessage, String me, String friend) {
    // Проверка, что файл существует
    File file =
        chatMessage.filePath != null ? File(chatMessage.filePath) : null;

    if (file != null && !file.existsSync()) {
      file = null;
    }

    return Message(
      key: UniqueKey(),
      localId: chatMessage.id,
      code: chatMessage.code,
      content: chatMessage.msg,
      ownerType:
          chatMessage.tuser == me ? OwnerType.receiver : OwnerType.sender,
      ownerName: chatMessage.tuser == me ? friend : me,
      time: DateTime.parse(chatMessage.time),
      url: chatMessage.url,
      urlType: chatMessage.urlType,
      file: file,
      fuser: chatMessage.fuser,
      tuser: chatMessage.tuser,
      sendState: chatMessage.sendState,
    );
  }

  /* Обновление пути до файла */
  static Future<void> updateFilePath(int pk, String filePath) async {
    final db = await openDB();
    int updated = await db.update(
      tableName,
      {'filePath': filePath},
      where: 'id = ?',
      whereArgs: [pk],
    );
  }

  /* Обновление кода */
  static Future<void> updateCode(int pk, int code) async {
    final db = await openDB();
    int updated = await db.update(
      tableName,
      {'code': code, 'sendState': SendStates.sent.index}, // отправлено
      where: 'id = ?',
      whereArgs: [pk],
    );
  }

  /* Обновление состояние отправки */
  static Future<void> updateSendState(int pk, int sendState) async {
    final db = await openDB();
    int updated = await db.update(
      tableName,
      {'sendState': sendState},
      where: 'id = ?',
      whereArgs: [pk],
    );
  }
}
