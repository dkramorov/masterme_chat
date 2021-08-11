import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileMessageWidget extends StatefulWidget {
  final String fname;
  final String url;
  final File file;

  FileMessageWidget({this.url, this.fname, this.file});

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

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      setState(() {
        downloadStatus = 'Загружен';
        downloaded = true;
        dest = widget.file;
      });
    }
  }

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

    //final dir = await getApplicationSupportDirectory();
    final dir = await getApplicationDocumentsDirectory();
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
      if (await Permission.storage.isPermanentlyDenied) {
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
    final containerWidth = MediaQuery.of(context).size.width * 0.5;
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
              SizedBox(
                width: containerWidth,
                child: Text(
                  'Файл: ' + widget.fname,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
              Text(downloadStatus),
            ],
          ),
        ],
      ),
    );
  }
}
