import 'database_singletone.dart';

/* Настройки в базе данных */
class SettingsModel extends AbstractModel {
  int id; // null if we need new row
  String attr;
  String key;
  String value;

  static final String tableName = 'settings';
  static final String attrJabber = 'Jabber';

  @override
  String getTableName() {
    return SettingsModel.tableName;
    ;
  }

  SettingsModel({this.id, this.attr, this.key, this.value});

  // Convert into a Map
  // The keys must correspond to the names of the
  // columns in the database
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attr': attr,
      'key': key,
      'value': value,
    };
  }

  // Implement toString to make it easier to see information
  @override
  String toString() {
    final String table = getTableName();
    return '$table{id: $id, attr: $attr, key: $key, value: $value}';
  }

  /* Получение настроек по attr и key
     вытаскиваем всегда первую настройку
   */
  static Future<SettingsModel> getByAttrKey(String attr, String key) async {
    final db = await openDB();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'attr = ? and key = ?',
      whereArgs: [attr, key],
    );
    if (maps.isEmpty) {
      return null;
    }
    final Map<String, dynamic> user = maps[0];
    return SettingsModel(
      id: user['id'],
      attr: user['attr'],
      key: user['key'],
      value: user['value'],
    );
  }

  /* Получаем адрес сервера Jabber из настроек */
  static Future<SettingsModel> getJabberServer() async {
    SettingsModel jabberServerSetting =
        await SettingsModel.getByAttrKey(SettingsModel.attrJabber, 'domain');
    if (jabberServerSetting != null) {
        return jabberServerSetting;
    }
  }

  /* Получаем версию обновления из настроек */
  static Future<int> getUpdateVersion() async {
    SettingsModel updateVersionSetting =
    await SettingsModel.getByAttrKey('update', 'version');
    if (updateVersionSetting != null) {
      return int.parse(updateVersionSetting.value);
    }
    return 0;
  }

  /* Сохраняем версию обновления в насктройки */
  static Future<void> setUpdateVersion(int version) async {
    SettingsModel updateVersionSetting =
    await SettingsModel.getByAttrKey('update', 'version');
    if (updateVersionSetting == null) {
      updateVersionSetting = SettingsModel(
        attr: 'update',
        key: 'version',
        value: '$version',
      );
    } else {
      updateVersionSetting.value = '$version';
    }
    updateVersionSetting.insert2Db();
  }

  // A method that retrieves all from the settings table.
  static Future<List<SettingsModel>> getAllSettings() async {
    // Get a reference to the database.
    final db = await openDB();

    // Query the table for all
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert the List<Map<String, dynamic> into a List<SettingsModel>.
    return List.generate(maps.length, (i) {
      return SettingsModel(
        id: maps[i]['id'],
        attr: maps[i]['attr'],
        key: maps[i]['key'],
        value: maps[i]['value'],
      );
    });
  }
}
