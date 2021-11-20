import 'dart:async';
import 'package:masterme_chat/db/chat_message_model.dart';
import 'package:masterme_chat/db/companies_sql_helper.dart';
import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/settings_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'chat_draft_model.dart';


const DB_VERSION = 32; // Версия базы данных

/*
https://stackoverflow.com/questions/1711631/improve-insert-per-second-performance-of-sqlite
https://www.sqlite.org/limits.html
*/

/* Вспомогательный класс для создания любой модели для базы данных */
class AbstractModel {
  int id; // null if we need new row
  static final String tableName = 'test';
  static final String dbName = 'settings.db';

  /* Companies database

  */
  static final String dbCompaniesName = 'companies.db';

  String getDbName() {
    return dbName;
  }

  String getTableName() {
    return tableName;
  }

  /* Выбираем какую базу открывать */
  Future<Database> selectOpenDb() async {
    if (getDbName() == dbCompaniesName) {
      return await openCompaniesDB();
    }
    // Стандартное поведение (база по умолчанию)
    return await openDB();
  }

  AbstractModel({this.id});

  static getInt(dynamic digit) {
    if (digit == null) {
      return 0;
    }
    digit = '$digit';
    return (digit != '') ? int.parse(digit) : 0;
  }

  static getDouble(dynamic digit) {
    if (digit == null) {
      return 0.0;
    }
    digit = '$digit';
    return (digit != '') ? double.parse(digit) : 0.0;
  }

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
    final db = await selectOpenDb();
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
    final db = await selectOpenDb();
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
    final db = await selectOpenDb();
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [this.id],
    );
  }

  Future<void> dropAllRows() async {
    final tableName = getTableName();
    final db = await selectOpenDb();
    final dropped = await db.delete(
      tableName,
    );
    Log.w('$tableName', 'dropAllRows = $dropped');
  }

  Future<int> getCount() async {
    final tableName = getTableName();
    final db = await selectOpenDb();
    int count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
    Log.i('$tableName', 'rows count = ${count.toString()}');
    return count;
  }

  /* Обновляем выборочные поля */
  Future<int> updatePartial(int pk, Map<String, dynamic> values) async {
    final tableName = getTableName();
    if (pk == null) {
      Log.e('[ERROR]: $tableName not updated', 'pk is null');
      return 0;
    }
    Log.d('updatePartial $tableName pk=$pk', '${values.toString()}');
    final db = await selectOpenDb();

    int updated = await db.update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [pk],
    );
    return updated;
  }

  /* Вставка в бд через транзакцию,
     запросы должены уже быть готовы к вставке

     'INSERT or REPLACE INTO Test(name, value, num) VALUES(?, ?, ?)',
     ['another name', 12345678, 3.1416]

     В массив ложим запросы с параметрами,
     то есть, первый элемент массива и последующие -
     это массивы, в каждом из которых первый элемент это
     сам запрос, а второй элемент - параметры
  */
  Future<void> transaction(List<dynamic> queriesWithParams) async {
    final tableName = getTableName();

    if (queriesWithParams.isEmpty) {
      Log.d('transaction $tableName', 'empty');
      return;
    }
    final db = await selectOpenDb();

    final elapser = Stopwatch();
    elapser.start();

    String query = queriesWithParams[0];
    List<dynamic> params = queriesWithParams[1];

    await db.transaction((txn) async {
      int count = await txn.rawInsert(query, params);
      //Log.d('transaction $tableName', 'inserted $count for query: $query, with params $params');
    });
    elapser.stop();
    Log.d('transaction ${db.path.split("/").last}.$tableName',
        'queries count: ${params.length}, elapsed ${elapser.elapsed.inMilliseconds}');
  }

  Future<void> massTransaction(List<dynamic> pages) async {
    /* Массовая вставка постранично разбитых запросов разом,
       тоже самое что transaction, только берем сразу много queriesWithParams
       pages = [queriesWithParams = [[query, params], [query, params], ...]]
    */
    final elapser = Stopwatch();
    elapser.start();
    final db = await selectOpenDb();
    final tableName = getTableName();
    await db.transaction((txn) async {
      for (List<dynamic> page in pages) {
        if (page.isEmpty) {
          Log.d('transaction $tableName', 'empty');
          continue;
        }
        String query = page[0];
        List<dynamic> params = page[1];
        await txn.rawInsert(query, params);
      }
    });
    elapser.stop();
    Log.d('transaction ${db.path.split("/").last}.$tableName',
        ', elapsed ${elapser.elapsed.inMilliseconds}');
  }

  /* Для сохранения всего говнища в базу,
     берем пачку моделей,
     подготавливаем запросы с параметрами
     останется отправить их в transaction()

     Если большой массив, надо делать постранично (start, end)
  */
  Future<List<dynamic>> prepareTransactionQueries(
      List<dynamic> models, int start, int end) async {
    List<dynamic> result = [];
    if (models.length == 0) {
      return result;
    }
    final tableName = getTableName();
    final keys = models[0].toMap().keys;
    String paramsPlaceholder = '(' + ('?, ' * (keys.length - 1)) + '?' + ')';
    String paramsNames = keys.join(',');
    List<String> paramsPlaceholders = [];
    List<dynamic> queryValues = []; // all values in the list

    String query = 'INSERT OR REPLACE INTO $tableName ($paramsNames) VALUES';

    if (end > models.length) {
      end = models.length;
    }
    List<dynamic> curSlice = models.sublist(start, end);
    for (var model in curSlice) {
      paramsPlaceholders.add(paramsPlaceholder); // Добавляем ?,?,? на каждую запись
      Map<String, dynamic> mapa = model.toMap();
      for (String paramName in keys) {
        // Все пихаем в длинный список
        queryValues.add(mapa[paramName]);
      }
    }
    return [query + paramsPlaceholders.join(','), queryValues];
  }
}

class DBInstance {
  static Database instance;
}

Future<Database> openDB() async {
  if (DBInstance.instance != null) {
    return DBInstance.instance;
  }

  // final String alterTableTestNewToTest = 'ALTER TABLE test_new RENAME TO test';

  final String createTableSettings =
      'CREATE TABLE IF NOT EXISTS ${SettingsModel.tableName}(id INTEGER PRIMARY KEY, attr TEXT, key TEXT, value TEXT)';
  final String createTableChatMessages =
      'CREATE TABLE IF NOT EXISTS ${ChatMessageModel.tableName}(id INTEGER PRIMARY KEY, fuser TEXT, tuser TEXT, code int, type TEXT, parent TEXT, time TEXT, msg TEXT, url TEXT, urlType TEXT, filePath TEXT, sendState int)';
  final String createTableChatDraft =
      'CREATE TABLE IF NOT EXISTS ${ChatDraftModel.tableName}(id INTEGER PRIMARY KEY, login TEXT, tuser TEXT, msg TEXT)';

  final indexCode = (AbstractModel.dbName + '.code').replaceAll('.', '_');
  final String indexCodeTableChatMessages =
      'CREATE INDEX IF NOT EXISTS $indexCode ON ${ChatMessageModel.tableName} (code)';

  final indexParent = (AbstractModel.dbName + '.parent').replaceAll('.', '_');
  final String indexParentTableChatMessages =
      'CREATE INDEX IF NOT EXISTS $indexParent ON ${ChatMessageModel.tableName} (parent)';

  final String alterTableChatMessagesAddFilePath =
      'ALTER TABLE ${ChatMessageModel.tableName} add filePath TEXT';
  final String alterTableChatMessagesAddSendState =
      'ALTER TABLE ${ChatMessageModel.tableName} add sendState int';

  /* ContactChatModel */
  final String contactName = 'name TEXT';
  final String contactAvatar = 'avatar TEXT';
  final String contactAvatarUrl = 'avatarUrl TEXT';
  final String contactStatus = 'status TEXT';
  final String contactParent = 'parent TEXT';
  final String contactTime = 'time TEXT';
  final String contactMsg = 'msg TEXT';
  final String createTableContacts = 'CREATE TABLE IF NOT EXISTS' +
      ' ${ContactChatModel.tableName}(' +
      'id INTEGER PRIMARY KEY, login TEXT' +
      ', $contactName' +
      ', $contactAvatar' +
      ', $contactAvatarUrl' +
      ', $contactStatus' +
      ', $contactParent' +
      ', $contactTime' +
      ', $contactMsg' +
      ')';
  final String alterTableContactsAddAvatarUrl =
      'ALTER TABLE ${ContactChatModel.tableName} add $contactAvatarUrl';

  /* UserHistoryModel */
  final String userHistoryTime = 'time text';
  final String userHistoryDuration = 'duration int';
  final String userHistorySource = 'source text';
  final String userHistoryDest = 'dest text';
  final String userHistoryAction = 'action text';
  final String userHistoryCompanyId = 'companyId int';
  final String createTableUserHistoryModel = 'CREATE TABLE IF NOT EXISTS' +
      ' ${UserHistoryModel.tableName}(' +
      'id INTEGER PRIMARY KEY, login TEXT' +
      ', $userHistoryTime' +
      ', $userHistoryDuration' +
      ', $userHistorySource' +
      ', $userHistoryDest' +
      ', $userHistoryAction' +
      ', $userHistoryCompanyId' +
      ')';
  final String alterTableUserHistoryAddCompanyId =
      'ALTER TABLE ${UserHistoryModel.tableName} add $userHistoryCompanyId';

  /* UserChatModel */
  final String userChatLastLogin = 'lastLogin int';
  final String userChatPhoto = 'photo text';
  final String userChatPhotoUrl = 'photoUrl text';
  final String userChatBirthday = 'birthday text';
  final String userChatGender = 'gender int';
  final String userChatEmail = 'email text';
  final String userChatName = 'name text';
  final String alterTableUserChatAddLastLogin =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatLastLogin';
  final String alterTableUserChatAddPhoto =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatPhoto';
  final String alterTableUserChatAddPhotoUrl =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatPhotoUrl';
  final String alterTableUserChatAddBirthday =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatBirthday';
  final String alterTableUserChatAddGender =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatGender';
  final String alterTableUserChatAddEmail =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatEmail';
  final String alterTableUserChatAddName =
      'ALTER TABLE ${UserChatModel.tableName} add $userChatName';
  final String createTableUserChatModel = 'CREATE TABLE IF NOT EXISTS' +
      ' ${UserChatModel.tableName}(' +
      'id INTEGER PRIMARY KEY, login TEXT, passwd TEXT' +
      ', $userChatLastLogin' +
      ', $userChatPhoto' +
      ', $userChatPhotoUrl' +
      ', $userChatBirthday' +
      ', $userChatGender' +
      ', $userChatEmail' +
      ', $userChatName' +
      ')';

  /* companies sql helper */
  void companiesSQL(Database db) {
    List<String> companiesSQLQueries = companiesSQLHelper();
    for (int i = 0; i < companiesSQLQueries.length; i++) {
      Log.d('companiesSQLHelper',
          'query ${i + 1} from ${companiesSQLQueries.length}');
      db.execute(companiesSQLQueries[i]);
    }
  }

  void createTables(Database db) {
    db.execute(createTableSettings);
    db.execute(createTableUserChatModel);
    db.execute(createTableContacts);
    db.execute(createTableChatMessages);
    db.execute(createTableChatDraft);
    db.execute(createTableUserHistoryModel);

    db.execute(indexCodeTableChatMessages);
    db.execute(indexParentTableChatMessages);
    companiesSQL(db);
  }

  final Future<Database> database = openDatabase(
    join(await getDatabasesPath(), AbstractModel.dbName),

    onCreate: (db, version) {
      createTables(db);
    },
    onUpgrade: (db, oldVersion, newVersion) {
      Log.i('--- DB UPGRADE ---', '$oldVersion=>$newVersion');
      createTables(db);

      if (oldVersion <= 15) {
        db.execute(alterTableChatMessagesAddFilePath);
      }
      if (oldVersion <= 16) {
        db.execute(alterTableChatMessagesAddSendState);
      }
      if (oldVersion <= 17) {
        db.execute(alterTableUserChatAddLastLogin);
      }
      if (oldVersion <= 20) {
        db.execute(alterTableUserChatAddPhoto);
        db.execute(alterTableUserChatAddBirthday);
        db.execute(alterTableUserChatAddGender);
        db.execute(alterTableUserChatAddEmail);
        db.execute(alterTableUserChatAddName);
      }
      if (oldVersion <= 23) {
        db.execute(alterTableUserChatAddPhotoUrl);
      }
      if (oldVersion <= 24) {
        db.execute(alterTableContactsAddAvatarUrl);
      }
      if (oldVersion <= 27) {
        companiesSQL(db);
      }
      if (oldVersion <= 28) {
        db.execute(alterTableUserHistoryAddCompanyId);
      }
      if (oldVersion <= 32) {
        final companiesDB = openCompaniesDB();
        companiesDB.then((dbinstance){
          final String icon = 'icon text';
          final String alterTableCatalogueAddIcon =
              'ALTER TABLE ${Catalogue.tableName} add $icon';
          dbinstance.execute(alterTableCatalogueAddIcon);
        });
      }
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: DB_VERSION,
  );
  DBInstance.instance = await database;
  return database;
}

class DBCompaniesInstance {
  static Database instance;
}

Future<Database> openCompaniesDB() async {
  if (DBCompaniesInstance.instance != null) {
    return DBCompaniesInstance.instance;
  }

  /* companies sql helper */
  void companiesSQL(Database db) {
    List<String> companiesSQLQueries = companiesSQLHelper();
    for (int i = 0; i < companiesSQLQueries.length; i++) {
      Log.d('companiesSQLHelper',
          'query ${i + 1} from ${companiesSQLQueries.length}');
      db.execute(companiesSQLQueries[i]);
    }
  }

  void createTables(Database db) {
    companiesSQL(db);
  }

  final Future<Database> database = openDatabase(
    join(await getDatabasesPath(), AbstractModel.dbCompaniesName),

    onCreate: (db, version) {
      createTables(db);
    },
    onUpgrade: (db, oldVersion, newVersion) {
      Log.i('--- DB UPGRADE ---', '$oldVersion=>$newVersion');
      createTables(db);
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: DB_VERSION,
  );
  DBCompaniesInstance.instance = await database;
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
  for (SettingsModel setting in allSettings) {
    print('from db:' + setting.toString());
  }
}
