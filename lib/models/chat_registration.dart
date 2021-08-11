import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RegistrationModel {
  static const TAG = 'RegistrationModel';
  final int id;
  final String created;
  final String updated;
  final bool is_active;
  final String phone;
  final String version;
  final String platform;
  final String result;

  RegistrationModel({
    this.id,
    this.created,
    this.updated,
    this.is_active,
    this.phone,
    this.version,
    this.platform,
    this.result,
  });

  @override
  String toString() {
    return 'id: $id, phone: $phone, result: $result, version: $version, platform: $platform, created: $created, updated: $updated, is_active: $is_active';
  }

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'] as int,
      created: json['created'] as String,
      updated: json['updated'] as String,
      is_active: json['is_active'] as bool,
      phone: json['phone'] as String,
      version: json['version'] as String,
      platform: json['platform'] as String,
      result: json.keys.contains('result') ? json['result'] : '',
    );
  }

  static RegistrationModel parseResponse(String responseBody) {
    //final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    //return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
    final parsed = jsonDecode(responseBody);
    return RegistrationModel.fromJson(parsed);
  }

  static Future<RegistrationModel> requestRegistration(String login, String passwd) async {
    final appInfo = await PackageInfo.fromPlatform();
    final appVersion = appInfo.version + '+' + appInfo.buildNumber;
    final queryParameters = {
      'action': 'registration',
      'phone': login,
      'passwd': passwd,
      'platform': Platform.operatingSystem,
      'version': appVersion,
    };
    final uri = Uri.https(JABBER_SERVER, JABBER_REG_ENDPOINT, queryParameters);
    Log.d(TAG, 'query: ${uri.toString()}');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return parseResponse(response.body);
    }
    return null;
  }

  static Future<RegistrationModel> confirmRegistration(String phone, String code) async {
    final queryParameters = {
      'action': 'confirm',
      'phone': phone,
      'code': code,
    };
    final uri = Uri.https(JABBER_SERVER, JABBER_REG_ENDPOINT, queryParameters);
    Log.d(TAG, 'query: ${uri.toString()}');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return parseResponse(response.body);
    }
    return null;
  }
}
