import 'package:flutter/material.dart';
import 'package:masterme_chat/db/settings_model.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';

// xmpp

class SettingsScreen extends StatefulWidget {
  static const String id = '/settings_screen/';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String jabberServer;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController jabberServerController = TextEditingController();

  @override
  void dispose() {
    jabberServerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    settingsFromDb();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /* Отправка формы с настройками */
  void settingsFormSubmit() async {
    if (!_formKey.currentState.validate()) {
      final snackBar = SnackBar(content: Text('Нельзя сохранить, проверьте ошибки в полях'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    _formKey.currentState.save();
    await settings2Db();
    //Navigator.pop(context, true);
    final snackBar = SnackBar(content: Text('Настройки сохранены'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /* Втыкаем настройки в базу */
  void settings2Db() async {
    SettingsModel jabberServerSetting =
        await SettingsModel.getByAttrKey(SettingsModel.attrJabber, 'domain');
    if (jabberServerSetting == null) {
      jabberServerSetting = SettingsModel(
        attr: SettingsModel.attrJabber,
        key: 'domain',
        value: jabberServer,
      );
    }
    jabberServerSetting.value = jabberServer;
    jabberServerSetting.insert2Db();
  }

  /* Вытаскиваем настройки из базы */
  Future<void> settingsFromDb() async {
    SettingsModel jabberServerSetting = await SettingsModel.getJabberServer();
    if (jabberServerSetting != null) {
      setState(() {
        jabberServer = jabberServerSetting.value;
        jabberServerController.text = jabberServer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Настройки',
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 40.0,
            horizontal: 40.0,
          ),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        suffix: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Адрес сервера',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        labelText: 'XMPP адрес домена',
                        labelStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.green,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.green[100],
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.green[100],
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.red[200],
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      onSaved: (value) {
                        jabberServer = value;
                      },
                      controller: jabberServerController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (String value) {
                        bool match =
                            RegExp(r'^[a-z0-9]+\.[a-z0-9\.]+$').hasMatch(value);
                        if (value.isEmpty || !match) {
                          return 'Неправильный адрес';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 25.0,
                    ),
                    RoundedButtonWidget(
                      text: Text(
                        'Сохранить',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.green[500],
                      onPressed: () {
                        settingsFormSubmit();
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
