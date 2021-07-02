import 'package:flutter/material.dart';

const PRIMARY_BG_COLOR = Color(0xFF0A0E21);

const SUBTITLE_STYLE = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 30.0,
);

const LOGO_NAME = 'Наш чат';
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