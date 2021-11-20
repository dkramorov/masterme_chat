import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/settings_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:http/http.dart' as http;

class ProfileScreenLogic extends AbstractScreenLogic {
  static const TAG = 'ProfileScreenLogic';

  ProfileScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      await checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  /* Выход */
  logout() async {
    JabberConn.clear();
    setStateCallback({'loading': false, 'loggedIn': false, 'logout': true});
    checkState();
  }

  /* Получение аргументов на вьюхе (пушь уведомление) */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {}
  }

  /* Загрузка изображения */
  void handleImageSelection({ImageSource source = ImageSource.gallery}) async {
    PickedFile result;
    try {
      result = await ImagePicker().getImage(
        source: source,
      );
    } catch (err) {
      setStateCallback({'permissionError': true});
      return;
    }
    if (result != null) {
      //Log.d(TAG, 'handleImageSelection ${result.path}');
      onPickImage(result.path);
    } else {
      // User canceled the picker
    }
  }

  Future<void> uploadImage(List<int> bytes, String fname) async {
    if (JabberConn.curUser == null) {
      return;
    }
    final url = 'https://$JABBER_SERVER$JABBER_VCARD_ENDPOINT';
    print(url);

    final uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri);
    request.fields['phone'] = JabberConn.curUser.login;
    request.fields['credentials'] = JabberConn.credentialsHash();
    print('app hash ${JabberConn.credentialsHash()}' +
    '\n ${JabberConn.curUser.login}');
    http.MultipartFile part = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fname,
    );
    request.files.add(part);
    http.StreamedResponse response = await request.send();
    var data = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final parsed = jsonDecode(data);
      String photoUrl = parsed['url'];
      if (photoUrl != null) {
        JabberConn.curUser.updatePartial(JabberConn.curUser.id, {
          'photoUrl': photoUrl,
        });
        JabberConn.curUser.photoUrl = photoUrl;
        JabberConn.vCardManager.updateVCard(JabberConn.curUser.toVCard());
      }
    }
  }

  Future<void> onPickImage(String fname) async {
    final storagePerms = await Permission.storage.status;
    if (!storagePerms.isGranted) {
      Log.e(TAG, 'Permissions absents');
      await [
        Permission.storage,
      ].request();
      return null;
    }
    final File file = File(fname);
    final bytes = await file.readAsBytes();
    final imageName = 'my_photo_' + file.path.split('/').last;
    final String destFolder = await SaveNetworkFile.makeAppFolder();

    final File dest = File(destFolder + '/' + imageName);
    dest.writeAsBytes(bytes);

    // Записать в базу
    if (JabberConn.curUser != null) {
      Map<String, dynamic> values = {
        'photo': dest.path,
      };
      JabberConn.curUser.updatePartial(
        JabberConn.curUser.id,
        values,
      );
      JabberConn.curUser.photo = dest.path;
    }
    // Обновить UI
    setStateCallback({'photo': dest.path});
    uploadImage(bytes, imageName);
  }

  Future<void> saveUserData({
    String name,
    String email,
    String birthday,
    int gender,
  }) async {
    // Записать в базу
    if (JabberConn.curUser != null) {
      Map<String, dynamic> values = {
        'name': name,
        'email': email,
        'birthday': birthday,
        'gender': gender,
      };
      await JabberConn.curUser.updatePartial(
        JabberConn.curUser.id,
        values,
      );
      // Получить юзера с новыми данными
      JabberConn.curUser =
          await UserChatModel.getByLogin(JabberConn.curUser.login);
      JabberConn.vCardManager.updateVCard(JabberConn.curUser.toVCard());
    }
  }

  Future<String> getUpdateVersion() async {
    // Получение версии базы данных
    int version = await SettingsModel.getUpdateVersion();
    return '$version';
  }
}
