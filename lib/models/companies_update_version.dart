import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:masterme_chat/services/telegram_bot.dart';

class CompaniesUpdateVersion {
  static const TAG = 'CompaniesUpateVersion';
  static bool DEBUG = false; // отладочные сообщения по обновлению
  final int version;

  CompaniesUpdateVersion({
    this.version,
  });

  @override
  String toString() {
    return 'version: $version';
  }

  factory CompaniesUpdateVersion.fromJson(Map<String, dynamic> json) {
    return CompaniesUpdateVersion(
      version: json['version'],
    );
  }

  static CompaniesUpdateVersion parseResponse(String responseBody) {
    final parsed = jsonDecode(responseBody);
    return CompaniesUpdateVersion.fromJson(parsed);
  }

  static Future<int> downloadUpdateVersion() async {
    String now = DateTime.now().toIso8601String(); // no cache param
    final url = '$DB_SERVER$DB_UPDATE_VERSION?t=$now';
    if(DEBUG) {
      Log.d(TAG, url);
    }
    final String destFolder = await SaveNetworkFile.makeAppFolder();
    final File dest = File(destFolder + '/version.json');
    Dio dio = new Dio();

    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      if(DEBUG) {
        print('onHttpClientCreate entered...');
      }
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };

    await dio.download(
      url,
      dest.path,
    );
    if(DEBUG) {
      Log.d(TAG, 'version number downloaded ${dest.path}');
    }
    String resp = await dest.readAsString();
    CompaniesUpdateVersion response = parseResponse(resp);

    if (response != null) {
      return response.version;
    }
    TelegramBot().sendError('$url update version number failed, resp $resp');
    return 0;
  }
}