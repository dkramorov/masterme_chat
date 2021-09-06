import 'dart:io';
import 'package:dio/dio.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SaveNetworkFile {
  static String TAG = 'SaveNetworkFile';

  static Future<void> makeAppFolder() async {

  }

  static Future<File> getFileFromNetwork(String url,
      {int dbPK, String type = 'chat'}) async {
    final storagePerms = await Permission.storage.status;
    if (!storagePerms.isGranted) {
      Log.e(TAG, 'Permissions absents');
      await [
        Permission.storage,
      ].request();
      return null;
    }
    final directory = await getApplicationDocumentsDirectory();
    final String destFolder = directory.path + '/' + APP_FOLDER;
    await new Directory(destFolder).create();
    final fileName = url.split('/').last;
    final File dest = File(destFolder + '/' + fileName);
    Dio dio = new Dio();
    await dio.download(
      url,
      dest.path,
    );
    Log.d(TAG, '---DOWNLOADED---\n${dest.path}');
    return dest;
  }
}
