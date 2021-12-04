import 'package:flutter/material.dart';

const int JABBER_PORT = 5222;
const String JABBER_SERVER = 'anhel.1sprav.ru';
//const String JABBER_SERVER = '127.0.0.1:8000';
const String JABBER_REG_ENDPOINT = '/jabber/register_user/';
const String JABBER_VCARD_ENDPOINT = '/jabber/vcard/';
//const String JABBER_NOTIFY_ENDPOINT = '/jabber/test_notification/';
const String JABBER_NOTIFY_ENDPOINT = '/jabber/notification/8800/';

const String APP_FOLDER = '8800help';

const PHONE_MASK = 1; // 8(800) 700-11-78
//const PHONE_MASK = 2; //8 (###) #-###-###

const SIP_SERVER = 'calls.223-223.ru';
const SIP_WSS = 'wss://calls.223-223.ru:7443';
const SIP_USER = '1000';
const SIP_PASSWD = 'cnfylfhnysq';

const DB_SERVER = 'https://chat.masterme.ru';
const DB_UPDATE_ENDPOINT = '/media/app_json/companies_db_helper.json';
const DB_LOGO_PATH = '/media/'; // Полный путь передаем, начиная с /media/
// Маршут, который говорит какая версия для обновления доступна
const DB_UPDATE_VERSION = '/media/app_json/version.json';

const String DEFAULT_AVATAR = 'assets/avatars/default_avatar.png';
//const PRIMARY_BG_COLOR = Color(0xFF0A0E21);
const PRIMARY_BG_COLOR = Color(0xFF0F741B);

const SUBTITLE_STYLE = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 30.0,
  color: kPrimaryColor,
);

const GREEN_TEXT_STYLE = TextStyle(
  fontSize: 20.0,
  color: kPrimaryColor,
);

const LOGO_NAME = '8800 help';
const LOGO_SIZE = 35.0;
const LOGO_ICON_TAG = 'logo_icon';
const SEARCH_ICON = 'assets/svg/bp_search_icon.svg';

const BORDER_RADIUS_48 = BorderRadius.all(
  Radius.circular(48.0),
);
const BORDER_RADIUS_32 = BorderRadius.all(
  Radius.circular(32.0),
);
const BORDER_RADIUS_16 = BorderRadius.all(
  Radius.circular(16.0),
);
const BORDER_RADIUS_8 = BorderRadius.all(
  Radius.circular(8.0),
);

const INPUT_DECORATION = InputDecoration(
  hintText: '',
  contentPadding: EdgeInsets.symmetric(
    vertical: 10.0,
    horizontal: 20.0,
  ),
  border: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_16,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_16,
    borderSide: BorderSide(
      color: kPrimaryColor,
      width: 1.0,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BORDER_RADIUS_16,
    borderSide: BorderSide(
      color: kPrimaryColor,
      width: 2.0,
    ),
  ),
);

// Primary Color
const kPrimaryColor = Colors.green;
const kPrimaryColor2 = Color(0xFF006917);
const kPrimaryDarkenColor = Color(0xFF2D3142);
const kBrightlyGreen = Color(0xFF4AF752);
// Background Color
const kBackgroundColor = Color(0xFFF7FFF5);
const kBackgroundLightColor = Color(0xFFFFFFFF);
// Box Color
const kDisabledButtonColor = Color(0xFFD2D2D2);
const kSizeBoxLightColor = Color(0xFFEBF3FF);
final kShadowColor = Color(0xFFB7B7B7).withOpacity(.15);
const kUnseletedColor = Color(0xFF91A2BA);
const kOutSideDateColor = Color(0xFFE9E9E9);
const kGrey = Color(0xFF54595D);
// Icon Color
const kIconFacebookColor = Color(0xFF3A58BA);
const kIconGoogleColor = Color(0xFFEB4335);
const kIconStarColor = Color(0xFFFFCF23);
// Tag Color
const kTagHotelColor = Color(0xFF59B9FD);
const kTagRentColor = Color(0xFF1F87FE);
const kTagFlightColor = Color(0xFFFF9B90);
const kTagEventColor = Color(0xFFAF8EFF);
// Rating Color
const kDangerRatingColor = Color(0xFFFF5050);
const kWarningRatingColor = Color(0xFFEDA566);
const kMediumRatingColor = Color(0xFFA5BF5C);
// Others
const kSubTextColor = Color(0xFF95A0AF);

// SIZE
const SIZED_BOX_W04 = SizedBox(width: 4);
const SIZED_BOX_W06 = SizedBox(width: 6);
const SIZED_BOX_W10 = SizedBox(width: 10);
const SIZED_BOX_W20 = SizedBox(width: 20);
const SIZED_BOX_W45 = SizedBox(width: 45);

const SIZED_BOX_H04 = SizedBox(width: 4);
const SIZED_BOX_H06 = SizedBox(height: 6);
const SIZED_BOX_H12 = SizedBox(height: 12);
const SIZED_BOX_H16 = SizedBox(height: 16);
const SIZED_BOX_H20 = SizedBox(height: 20);
const SIZED_BOX_H24 = SizedBox(height: 24);
const SIZED_BOX_H30 = SizedBox(height: 30);
const SIZED_BOX_H45 = SizedBox(height: 45);

// PADDING
const PAD_ONLY_T10 = EdgeInsets.only(top: 10);
const PAD_ONLY_T20 = EdgeInsets.only(top: 20);
const PAD_ONLY_T40 = EdgeInsets.only(top: 40);
const PAD_ONLY_R20 = EdgeInsets.only(right: 20);
const PAD_SYM_H10 = EdgeInsets.symmetric(horizontal: 10);
const PAD_SYM_H16 = EdgeInsets.symmetric(horizontal: 16);
const PAD_SYM_H20 = EdgeInsets.symmetric(horizontal: 20);
const PAD_SYM_H30 = EdgeInsets.symmetric(horizontal: 30);
const PAD_SYM_V10 = EdgeInsets.symmetric(vertical: 10);
const PAD_SYM_V20 = EdgeInsets.symmetric(vertical: 20);

// STRING
const SGN_SIGNIN_TEXT = 'Вход';
const SGN_SIGNOUT_TEXT = 'Выход';
const SGN_NOACC_TEXT = 'Не зарегистрирован? Самое время!';
const SGN_SIGNUP_TEXT = 'Регистрация';
const SGN_PHONE_TEXT = 'Ваш телефон';
const SGN_HINT_PHONE_TEXT = '89148223223';
const SGN_PASS_TEXT = 'Ваш пароль';
const SGN_FORGET_PASSWD_TEXT = 'Не помню пароль';

const SGP_VERIFY_NUMBER_TEXT = 'Подтвердите телефон';
const SGP_SEND_MESSAGE_TEXT = 'Введите проверочный код, который вы прослушали';
const SGP_CONFIRM_TEXT = 'Подтвердить';

const SGP_SETUP_PASS_TEXT = 'Ваш пароль';
const SGP_HINT_PASS_TEXT = 'Придумайте ваш пароль';

const SGP_ADD_PHONE_TEXT = 'Регистрация';
const SGP_RESTORE_PHONE_TEXT = 'Восстановление пароля';
const SGP_PHONE_NOTICE_TEXT = 'Введите ваш номер телефона, ' +
    'вам поступит звонок и будет продиктован код подтверждения';
const SGP_SEND_OTP_TEXT = 'Запросить код';
const SGP_LOGOUT_TEXT = 'Выход';

const CATALOGUE_IN_UPDATE = 'Каталог обновляется';
const PLEASE_WAIT = 'Пожалуйста, подождите несколько секунд';