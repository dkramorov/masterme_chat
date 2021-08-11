import 'package:flutter/material.dart';

const int DB_VERSION = 17;
const int JABBER_PORT = 5222;
const String JABBER_SERVER = 'anhel.1sprav.ru';
const String JABBER_REG_ENDPOINT = '/jabber/register_user/';
const String JABBER_NOTIFY_ENDPOINT = '/jabber/test_notification/';

//const PRIMARY_BG_COLOR = Color(0xFF0A0E21);
const PRIMARY_BG_COLOR = Color(0xFF0F741B);

const SUBTITLE_STYLE = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 30.0,
  color: Colors.green,
);

const GREEN_TEXT_STYLE = TextStyle(
  fontSize: 20.0,
  color: Colors.green,
);

const LOGO_NAME = '8800 help';
const LOGO_SIZE = 35.0;
const LOGO_ICON_TAG = 'logo_icon';

const BORDER_RADIUS_32 = BorderRadius.all(
  Radius.circular(32.0),
);

const INPUT_DECORATION = InputDecoration(
  hintText: '',
  contentPadding: EdgeInsets.symmetric(
    vertical: 10.0,
    horizontal: 20.0,
  ),
  border: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_32,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_32,
    borderSide: BorderSide(
      color: Colors.blueAccent,
      width: 1.0,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_32,
    borderSide: BorderSide(
      color: Colors.blueAccent,
      width: 2.0,
    ),
  ),
);