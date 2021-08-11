import 'package:masterme_chat/db/chat_message_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/settings_model.dart';
import 'package:masterme_chat/helpers/log.dart';

import 'package:masterme_chat/constants.dart';

import 'chat_draft_model.dart';

/* Вспомогательный класс для создания любой модели для базы данных */
class AbstractModel {
  int id; // null if we need new row
  static final String tableName = 'test';
  static final String dbName = 'settings.db';

  String getTableName() {
    return tableName;
  }

  AbstractModel({this.id});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }

  @override
  String toString() {
    return 'Setting{id: $id}';
  }

  Future<void> insert2Db() async {
    final tableName = getTableName();
    Log.i('$tableName insert2Db', '${this.toMap().toString()}');
    final db = await openDB();
    // id null if we need new row
    int pk = await db.insert(
      tableName,
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    this.id = pk;
  }

  Future<void> update2Db() async {
    final tableName = getTableName();
    if (this.id == null) {
      Log.e('$tableName update2Db', 'id is null, we can not update');
      return;
    }
    final db = await openDB();
    await db.update(
      tableName,
      this.toMap(),
      where: 'id = ?',
      whereArgs: [this.id],
    );
  }

  Future<void> delete2Db() async {
    final tableName = getTableName();
    if (this.id == null) {
      Log.e('$tableName delete2Db', 'id is null, we can not drop');
      return;
    }
    final db = await openDB();
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [this.id],
    );
  }

  Future<void> dropAllRows() async {
    final tableName = getTableName();
    final db = await openDB();
    final dropped = await db.delete(
      tableName,
    );
    Log.w('$tableName', 'dropAllRows = $dropped');
  }

  Future<int> getCount() async {
    final tableName = getTableName();
    final db = await openDB();
    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
    Log.i('$tableName', 'rows count = ${count.toString()}');
    return count;
  }


}

class DBInstance {
  static Database instance;
}

Future<Database> openDB() async {
  if (DBInstance.instance != null) {
    return DBInstance.instance;
  }
  //WidgetsFlutterBinding.ensureInitialized();

  //final String create_table_test_new = 'CREATE TABLE IF NOT EXISTS test_new(id INTEGER PRIMARY KEY)';
  final String createTableTest = 'CREATE TABLE IF NOT EXISTS test(id INTEGER PRIMARY KEY)';

  final String alterTableTestNewToTest = 'ALTER TABLE test_new RENAME TO test';
  final String createTableSettings = 'CREATE TABLE IF NOT EXISTS ${SettingsModel.tableName}(id INTEGER PRIMARY KEY, attr TEXT, key TEXT, value TEXT)';
  final String createTableUsers = 'CREATE TABLE IF NOT EXISTS ${UserChatModel.tableName}(id INTEGER PRIMARY KEY, login TEXT, passwd TEXT)';
  final String createTableContacts = 'CREATE TABLE IF NOT EXISTS ${ContactChatModel.tableName}(id INTEGER PRIMARY KEY, login TEXT, name TEXT, avatar TEXT, status TEXT, parent TEXT, time TEXT, msg TEXT)';
  final String createTableChatMessages = 'CREATE TABLE IF NOT EXISTS ${ChatMessageModel.tableName}(id INTEGER PRIMARY KEY, fuser TEXT, tuser TEXT, code int, type TEXT, parent TEXT, time TEXT, msg TEXT, url TEXT, urlType TEXT, filePath TEXT, sendState int)';
  final String createTableChatDraft = 'CREATE TABLE IF NOT EXISTS ${ChatDraftModel.tableName}(id INTEGER PRIMARY KEY, login TEXT, tuser TEXT, msg TEXT)';

  final indexCode = (AbstractModel.dbName + '.code').replaceAll('.', '_');
  final String indexCodeTableChatMessages = 'CREATE INDEX IF NOT EXISTS $indexCode ON ${ChatMessageModel.tableName} (code)';

  final indexParent = (AbstractModel.dbName + '.parent').replaceAll('.', '_');
  final String indexParentTableChatMessages = 'CREATE INDEX IF NOT EXISTS $indexParent ON ${ChatMessageModel.tableName} (parent)';

  final String alterTableChatMessagesAddFilePath = 'ALTER TABLE ${ChatMessageModel.tableName} add filePath TEXT';
  final String alterTableChatMessagesAddSendState = 'ALTER TABLE ${ChatMessageModel.tableName} add sendState int';

  void createTables(Database db) {
    db.execute(createTableTest);
    db.execute(createTableSettings);
    db.execute(createTableUsers);
    db.execute(createTableContacts);
    db.execute(createTableChatMessages);
    db.execute(createTableChatDraft);

    db.execute(indexCodeTableChatMessages);
    db.execute(indexParentTableChatMessages);
  }

  final Future<Database> database = openDatabase(
    join(await getDatabasesPath(), AbstractModel.dbName),

    onCreate: (db, version) {
      createTables(db);
    },
    onUpgrade: (db, oldVersion, newVersion) {
      Log.i('--- DB UPGRADE ---', '$oldVersion=>$newVersion');
      createTables(db);

      if (oldVersion == 0 && newVersion == 1) {
        db.execute(alterTableTestNewToTest);
      }
      if (oldVersion <= 15) {
        db.execute(alterTableChatMessagesAddFilePath);
      }
      if (oldVersion <= 16) {
        db.execute(alterTableChatMessagesAddSendState);
      }
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: DB_VERSION,
  );
  DBInstance.instance = await database;
  return database;
}


void demoWorkWithDb() async {
  // Create test settings and insert into database
  var testSetting = SettingsModel(
    id: 0,
    attr: 'potestua attr',
    key: 'potestua key',
    value: 'potestua value',
  );
  await testSetting.insert2Db();

  // Update Fido's age and save it to the database.
  testSetting = SettingsModel(
    id: 1,
    attr: testSetting.attr + '-1',
    key: testSetting.key + '-2',
    value: testSetting.value + '-3',
  );
  await testSetting.update2Db();

  await testSetting.delete2Db();

  final allSettings = await SettingsModel.getAllSettings();
  for(SettingsModel setting in allSettings) {
    print('from db:' + setting.toString());
  }
}
