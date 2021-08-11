import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/*
play() async {
  // https://pub.dev/packages/audioplayers/versions/0.17.4
  AudioPlayer audioPlayer = AudioPlayer();
  int result = await audioPlayer.play('https://s64iva.storage.yandex.net/get-mp3/f0d3c21abe16e288c7e815cfacb766ef/0005c8790e3302ed/rmusic/U2FsdGVkX19FG9Iup5-d9AO9rHmrZLrba7U3mDdYt_vcV_Tzb7hsRWhtmdspGgQ-p0mYOFn70H59mDAOnzfoxSOgwO5yIgXKTtCIOaSVgT4/8e91ab7997845031305b949694e00757eae7b97e4d889b5c919371e214163f34/23215?track-id=68254126&play=false');
  if (result == 1) {
    // success
  }
}
 */

class FileMessageWidget extends StatefulWidget {
  final String fname;
  final String url;

  FileMessageWidget({this.url, this.fname});

  @override
  _FileMessageWidgetState createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget> {
  static const String TAG = 'FileMessageWidget';
  bool downloaded = false;
  bool downloading = false;
  int downlodPercent = 0;
  String downloadStatus = 'Не загружен';
  File dest;

  void downloadFile() async {
    // если уже загружен или еще загружается
    if (downloading) {
      print('already downloading');
      return;
    }
    if (downloaded) {
      print('already downloaded');
      if (dest != null) {
        OpenFile.open(dest.path);
      } else {
        openInfoDialog(context, () {}, 'Ошибка открытия файла',
            'Не удалось открыть файл, откройте вкладку заново', 'Понятно');
      }
      return;
    }

    final dir = await getApplicationSupportDirectory();
    final String path = dir.path;
    final String fname = widget.url.split('/').last;
    dest = File('$path/$fname');

    final storagePerms = await Permission.storage.status;
    Log.i(TAG, 'storage perms status $storagePerms');
    Log.i(TAG, 'source ${widget.url} destination $dest');

    if (storagePerms.isGranted) {
      downloading = true;
      Dio dio = new Dio();
      Response response = await dio.download(
        widget.url,
        dest.path,
        onReceiveProgress: (_c, _t) {
          int percent = (_c / _t * 100).toInt();
          setState(() {
            downloadStatus = 'Загружается $percent%';
          });
        },
      );
      downloading = false;
      downloaded = true;
      downloadStatus = 'Загружен';
      //dest.writeAsString('I am the dummy_doc dot txt.');
    } else {
      if (await Permission.speech.isPermanentlyDenied) {
        // The user opted to never again see the permission request dialog for this
        // app. The only way to change the permission's status now is to let the
        // user manually enable it in the system settings.
        openAppSettings();
      } else {
        await [
          Permission.storage,
        ].request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        downloadFile();
      },
      child: Row(
        children: [
          Icon(
            Icons.file_present,
            size: 40.0,
            color: Colors.grey,
          ),
          SizedBox(
            width: 15.0,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Файл: ' + widget.fname),
              Text(downloadStatus),
            ],
          ),
        ],
      ),
    );
  }
}
