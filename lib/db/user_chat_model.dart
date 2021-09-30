import 'dart:io';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/database_singletone.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

/* Пользователи чата в базе данных
   для ростера контакты хранятся отдельно
   эта модель только для нашего пользотеля
*/
class UserChatModel extends AbstractModel {
  static const String TAG = 'UserChatModel';

  Key key = UniqueKey();

  int id; // null if we need new row
  String login;
  String passwd;
  int lastLogin;
  String photo;
  String photoUrl;
  String birthday;
  int gender;
  String email;
  String name;

  static final String tableName = 'users_chat';

  @override
  String getTableName() {
    return UserChatModel.tableName;
  }

  UserChatModel({
    this.id,
    this.login,
    this.passwd,
    this.lastLogin,
    this.photo,
    this.photoUrl,
    this.birthday,
    this.gender,
    this.email,
    this.name,
  });

  String getLogin() {
    return this.login.replaceAll('@$JABBER_SERVER', '');
  }

  String getName() {
    if (this.name != null && this.name != '') {
      return this.name;
    }
    return phoneMaskHelper(this.login.replaceAll('@$JABBER_SERVER', ''));
  }

  String getPhoto() {
    if (this.photo != null && this.photo != '') {
      if (!File(this.photo).existsSync()) {
        dowloadPhoto();
        return DEFAULT_AVATAR;
      }
      return this.photo;
    }
    return DEFAULT_AVATAR;
  }

  /* Загружаем аватарку если ссыль есть */
  Future<void> dowloadPhoto() async {
    UserChatModel self = this;
    if (self.photoUrl != null && self.photoUrl.startsWith('http')) {
      SaveNetworkFile.getFileFromNetwork(self.photoUrl).then((photo) {
        this.updatePartial(self.id, {
          'photoUrl': self.photoUrl,
          'photo': photo.path,
        });
        self.photo = photo.path;
        self.key = UniqueKey();
      });
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'passwd': passwd,
      'lastLogin': lastLogin,
      'photo': photo,
      'photoUrl': photoUrl,
      'birthday': birthday,
      'gender': gender,
      'email': email,
      'name': name,
    };
  }

  /* Собираем VCard */
  Map<String, String> toVCard() {
    Map<String, String> result = {};
    if (name != null && name != '') {
      result['FN'] = name;
    }
    if (birthday != null && birthday != '') {
      result['BDAY'] = birthday;
    }
    if (photoUrl != null && photoUrl != '') {
      result['IMAGE'] = photoUrl;
    }
    if (gender != null && gender != '') {
      result['SEX'] = gender.toString();
    }
    if (email != null && email != '') {
      result['MAIL'] = email;
    }
    Log.d(TAG, 'VCard: $result');
    return result;
  }

  /* Обновление данных пользователя из vCard */
  Future<void> updateFromVCard(VCard vCard) async {
    bool curUserUpdated = false; // для всех полей
    Log.d(TAG, 'Your vCard' + vCard.buildXmlString());
    // Надо обновить curUser из vCard там, где считаем нужным
    final curUserPhoto = JabberConn.curUser.photo;
    final bool vCardWithImage =
        vCard.imageByUrl != null && vCard.imageByUrl.startsWith('http');
    final bool curUserWithImage = curUserPhoto != null && curUserPhoto != '';
    if (vCardWithImage && !curUserWithImage) {
      SaveNetworkFile.getFileFromNetwork(vCard.imageByUrl).then((photo) {
        JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
          'photo': photo.path,
          'photoUrl': vCard.imageByUrl,
        });
        JabberConn.curUser.photo = photo.path;
        JabberConn.curUser.photoUrl = vCard.imageByUrl;
      });
    }
    if (vCard.fullName != JabberConn.curUser.name) {
      JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
        'name': vCard.fullName,
      });
      curUserUpdated = true;
    }
    if (vCard.bDay != JabberConn.curUser.birthday) {
      JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
        'birthday': vCard.bDay,
      });
      curUserUpdated = true;
    }
    if (vCard.sex != JabberConn.curUser.gender.toString()) {
      JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
        'gender': vCard.sex,
      });
      curUserUpdated = true;
    }
    if (vCard.mail != JabberConn.curUser.email) {
      JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
        'email': vCard.mail,
      });
      curUserUpdated = true;
    }
    // Если что-то обновилось, тогда с базы подтягиваем curUser
    if (curUserUpdated) {
      Future.delayed(Duration(seconds: 1), () async {
        JabberConn.curUser =
            await UserChatModel.getByLogin(JabberConn.curUser.login);
      });
    }
  }

  /* Перегоняем данные из базы в модельку */
  static UserChatModel toModel(Map<String, dynamic> dbItem) {
    return UserChatModel(
      id: dbItem['id'],
      login: dbItem['login'],
      passwd: dbItem['passwd'],
      lastLogin: dbItem['lastLogin'],
      photo: dbItem['photo'],
      photoUrl: dbItem['photoUrl'],
      birthday: dbItem['birthday'],
      gender: dbItem['gender'],
      email: dbItem['email'],
      name: dbItem['name'],
    );
  }

  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, login: $login, passwd: $passwd,' +
        ' lastLogin: $lastLogin, photo: $photo, photoUrl: $photoUrl, birthday: $birthday,' +
        ' gender: $gender, email: $email, name: $name}';
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
    return toModel(user);
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
  static Future<UserChatModel> insertLastLoginUser(
      String login, String passwd) async {
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
      user.passwd = passwd;
    }
    await user.insert2Db();
    return user;
  }
}
