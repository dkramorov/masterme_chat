import 'dart:io';

import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/screens/auth/auth.dart';
import 'package:masterme_chat/screens/logic/profile_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/my_elevated_button_widget.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';

class TabProfileView extends StatefulWidget {
  final PageController pageController;

  TabProfileView({this.pageController});

  @override
  _TabProfileViewState createState() => _TabProfileViewState();
}

class _TabProfileViewState extends State<TabProfileView> {
  static const TAG = 'TabProfileView';
  ProfileScreenLogic logic;
  bool loggedIn = false;

  bool _status = true;
  bool loading = false;
  String photo = DEFAULT_AVATAR;

  String name = '';
  TextEditingController nameController = TextEditingController();
  String email = '';
  TextEditingController emailController = TextEditingController();
  String birthday = '';
  TextEditingController birthdayController = TextEditingController();
  int gender = 1;

  @override
  void initState() {
    logic = ProfileScreenLogic(setStateCallback: setStateCallback);
    logic.checkState();
    super.initState();
  }

  @override
  void deactivate() {
    logic.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    logic.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void setName() {
    name = JabberConn.curUser.name != null ? JabberConn.curUser.name : '';
    nameController.text = name;
  }
  void setEmail() {
    email = JabberConn.curUser.email != null ? JabberConn.curUser.email : '';
    emailController.text = email;
  }
  void setBirthday() {
    birthday = JabberConn.curUser.birthday != null ? JabberConn.curUser.birthday : '';
    birthdayController.text = birthday;
  }

  void setStateCallback(Map<String, dynamic> newState) {
    setState(() {
      if (newState['loggedIn'] != null && newState['loggedIn'] != loggedIn && JabberConn.curUser != null) {
        photo = JabberConn.curUser.photo != null ? JabberConn.curUser.photo : DEFAULT_AVATAR;
        setName();
        setEmail();
        setBirthday();
        gender = JabberConn.curUser.gender != null ? JabberConn.curUser.gender : 1;
      }
      if (newState['photo'] != null && newState['photo'] != photo) {
        photo = newState['photo'];
      }
    });
    if (newState['logout'] != null && newState['logout'] == true) {
      Navigator.pushNamed(context, AuthScreen.id);
    }
    if (newState['permissionError'] != null) {
      permissionsErrorDialog('фото', context);
    }
  }

  Widget buildView() {
    return Container(
      color: Colors.white,
      child: new ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                height: 250.0,
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 20.0,
                        top: 20.0,
                      ),
                      child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Icon(
                            Icons.phone_iphone,
                            color: Colors.black54,
                            size: 24.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 25.0),
                            child: new Text(
                              JabberConn.curUser != null
                                  ? JabberConn.curUser.getLogin()
                                  : 'Ваш профиль',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Stack(
                        fit: StackFit.loose,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 140.0,
                                height: 140.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: photo.startsWith('assets')
                                        ? ExactAssetImage(
                                            photo,
                                          )
                                        : FileImage(
                                            File(photo),
                                          ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: 90.0,
                              right: 100.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                GestureDetector(
                                  child: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    radius: 25.0,
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onTap: () {
                                    logic.handleImageSelection();
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Color(0xffFFFFFF),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 25.0),
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 25.0,
                        ),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Персональная информация',
                                  style: TextStyle(
                                    fontSize: 19.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _status ? _getEditIcon() : Container(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 25.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'Ваше имя',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Flexible(
                              child: TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Введите ваше имя',
                                ),
                                enabled: !_status,
                                autofocus: !_status,
                                onChanged: (newName) {
                                  setState(() {
                                    name = newName;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 25.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'Ваш Email',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  hintText: 'Введите ваш Email',
                                ),
                                enabled: !_status,
                                onChanged: (newEmail) {
                                  setState(() {
                                    email = newEmail;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 25.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                child: Text(
                                  'Дата рождения',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              flex: 2,
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'Пол',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              flex: 2,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 25.0,
                          right: 25.0,
                          top: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: birthdayController,
                                  decoration: const InputDecoration(
                                    hintText: 'Дата рождения',
                                  ),
                                  enabled: !_status,
                                  onChanged: (newBirthday) {
                                    setState(() {
                                      birthday = newBirthday;
                                    });
                                  },
                                ),
                              ),
                              flex: 2,
                            ),
                            Flexible(
                              child: _buildSelectGender(),
                              flex: 2,
                            ),
                          ],
                        ),
                      ),
                      !_status ? _getActionButtons() : buildLogoutButton(),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(right: 30.0),
                alignment: Alignment.centerRight,
                child: Text(
                  JabberConn.appVersion != null ? JabberConn.appVersion : '',
                  style: TextStyle(
                    color: kDisabledButtonColor,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectGender() {
    return _status
        ? Center(
            child: Text(gender == 1 ? 'Муж' : 'Жен'),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Жен'),
              Switch(
                value: gender == 1 ? true : false,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      gender = 1;
                    } else {
                      gender = 2;
                    }
                  });
                },
                activeTrackColor: Colors.green,
                activeColor: Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.green,
              ),
              Text('Муж'),
            ],
          );
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 45.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                child: MyElevatedButton(
                  child: Text('Сохранить'),
                  color: Colors.green,
                  onPressed: () {
                    logic.saveUserData(
                      name: name,
                      email: email,
                      birthday: birthday,
                      gender: gender,
                    );
                    setState(() {
                      _status = true;
                    });
                  },
                ),
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                child: MyElevatedButton(
                  child: Text(
                    'Отмена',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _status = true;
                    });
                  },
                  color: Colors.red,
                ),
              ),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

  Widget buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: 25.0,
        right: 25.0,
        top: 45.0,
      ),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundedButtonWidget(
              text: Text(
                SGP_LOGOUT_TEXT,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              color: Colors.red,
              onPressed: () {
                logic.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getEditIcon() {
    return new GestureDetector(
      child: new CircleAvatar(
        backgroundColor: Colors.green,
        radius: 14.0,
        child: new Icon(
          Icons.edit,
          color: Colors.white,
          size: 16.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: buildView(),
      ),
    );
  }
}
