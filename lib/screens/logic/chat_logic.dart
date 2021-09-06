import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:masterme_chat/db/chat_draft_model.dart';
import 'package:masterme_chat/db/chat_message_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/message_widget.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/constants.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

/*
Стратегия:
1) загружаем сообщения с базы, выводим на экран,
2) отправляем запрос на сервер по завершению
3) если прилетели сообщения - обновляем, сортируем
*/
class ChatScreenLogic extends AbstractScreenLogic {
  static const TAG = 'ChatScreenLogic';

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  String me;
  String friend;

  String username = 'unknown';
  String image = 'assets/avatars/man1.jpg';
  xmpp.Buddy buddy;

  bool historyCompleted = false;
  List<Message> messageList = [];

  bool isDbMessagesLoaded = false;
  bool isServerMessagesLoaded = false;

  ChatScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  /* Получение аргументов на вьюхе (пользователь) */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {
      username = arguments['name'];
      image = arguments['image'];
      buddy = arguments['buddy'];
      JabberConn.receiver = username;

      me = JabberConn.connection?.fullJid?.userAtDomain;
      friend = buddy.jid.userAtDomain;
    }
  }

  /* Загрузка подтвержденных сообщений из базы
     Выполняем при загрузке экрна
  */
  Future<List<Message>> loadMessagesFromDb() async {
    List<Message> messages = [];

    final List<ChatMessageModel> chatMessages =
        await ChatMessageModel.getByParent(
      me,
      me,
      friend,
      orderBy: 'code DESC',
      limit: 20,
    );
    // В обратном порядке
    for (ChatMessageModel item in chatMessages.reversed) {
      messages.add(ChatMessageModel.convert2Message(item, me, friend));
    }
    return messages;
  }

  /* Загрузка не подтвержденных (без кода) сообщений из базы */
  Future<List<Message>> loadBrokenMessagesFromDb() async {
    List<Message> messages = [];
    /* Неотправленные сообщения */
    final List<ChatMessageModel> brokenMessages =
        await ChatMessageModel.getByParentNullSent(me, me, friend);

    /* Отправляем только с нулевым статусом,
       только если есть связь
    */
    if (JabberConn.connection?.state == xmpp.XmppConnectionState.Ready ||
        JabberConn.connection?.state == xmpp.XmppConnectionState.Resumed) {
      for (ChatMessageModel msg in brokenMessages) {
        if (msg.sendState == SendStates.none.index) {
          JabberConn.messageHandler.sendMessage(buddy.jid, msg.msg,
              url: msg.url, urlType: msg.urlType, localId: msg.id.toString());
          ChatMessageModel.updateSendState(msg.id, SendStates.pending.index);
        }
      }
    }
    return messages;
  }

  /* Достаем обычные сообщения из базы
     Достаем сломанные сообщения из базы
     Объединяем их в массив и вызываем callback на них
     по сути там setState в callback
  */
  Future<void> loadAllMessagesFromDb() async {
    // Вызывать будем только раз
    if (isDbMessagesLoaded) {
      return null;
    }
    isDbMessagesLoaded = true;
    final List<Message> messages = await loadMessagesFromDb();
    final List<Message> brokenMessages = await loadBrokenMessagesFromDb();
    messageList.addAll(messages + brokenMessages);
    // Обновляем экран
    setStateCallback(
      messageList,
      loggedIn,
    );
  }

  /* Отправляем запрос на сервер по сообщениям
     Если по ним будет получен ответ, тогда мы заменим
     все сообщения на них
  */
  Future<void> loadMessagesFromServer() async {
    // Вызывать будем только раз
    if (isServerMessagesLoaded) {
      return;
    }
    isServerMessagesLoaded = true;
    JabberConn.messageArchiveManager.queryLastMessages(jid: buddy.jid);
  }

  Future<void> loadAllMessages() async {
    await loadAllMessagesFromDb();
    loadMessagesFromServer();
  }

  /* Обработка сообщения от сервера по подписке
     на получение истории сообщений
  */
  void mamPaginator(Map<String, String> event) {
    if (event['complete'] == 'false') {
      historyCompleted = false;
    } else {
      historyCompleted = true;
    }
  }

  /* Вставка в базу сообщения если нет,
     filePath намеренно не обновляем,
     чтобы не потереть пока он обновляется фоново
  */
  Future<void> insertMessage2DbIfNotExists(ChatMessageModel msg) async {
    if (msg.code == null) {
      return;
    }
    ChatMessageModel analog = await ChatMessageModel.getAnalog(
      parent: me,
      code: msg.code,
      pk: msg.id,
      tuser: msg.tuser,
      fuser: msg.fuser,
    );

    if (analog == null) {
      msg.id = null; // Обязательно, т/к скорее всего ид собеседника приехал
      await msg.insert2Db();
    } else if (analog != null && analog.code == null) {
      // Обновляем ид у приехавщего сообщения
      msg.id = analog.id;
      await ChatMessageModel.updateCode(msg.id, msg.code);
      if (msg.filePath != null && msg.urlType == 'image') {
        File dest =
            await SaveNetworkFile.getFileFromNetwork(msg.url, dbPK: msg.id);
        ChatMessageModel.updateFilePath(analog.id, dest.path);
      }
    }
  }

  /* Сортировка списка сообщений с учетом того,
     что могут быть code=null, такие не сортируем,
     просто добавляем
  */
  void sortMessageList() {
    List<Message> withCodes = [];
    List<Message> withoutCodes = [];
    for (Message msg in messageList) {
      if (msg.code != null) {
        withCodes.add(msg);
      } else {
        withoutCodes.add(msg);
      }
    }
    withCodes.sort((a, b) => a.code.compareTo(b.code));
    messageList = withCodes + withoutCodes;
  }

  /* Парсим входящее сообщение
     Оно может быть архивным,
     может быть онлайн
  */
  void parseReceivedMessage(xmpp.Message msg) {
    if (msg.type == xmpp.MessageStanzaType.ERROR) {
      return null;
    }
    Message newMsg = receiveMessage(msg);
    if (newMsg == null) {
      Log.e(TAG, 'newMsg is null from receiveMessage ${msg.toString()}');
      return;
    }

    for (Message chatMessage in messageList) {
      // Обязательно, блять не null
      if (newMsg.code != null && newMsg.code == chatMessage.code) {
        // Сообщение есть в списке
        return;
      } else if (newMsg.localId == chatMessage.localId &&
          chatMessage.code == null &&
          chatMessage.fuser == me) {
        // Мы отправили сообщение
        // Сообщение есть в списке, но пока без кода

        // После обновления базы обновляем UI
        chatMessage.code = newMsg.code;
        chatMessage.key = UniqueKey();

        // Код поменяли, меняем состояние
        setStateCallback(
          messageList,
          loggedIn,
        );

        return;
      }
    }
    Log.d(TAG, 'add new message to list ${newMsg.debugString()}');
    messageList.add(newMsg);
    sortMessageList(); // Сортировка с учетом null
    setStateCallback(
      messageList,
      loggedIn,
    );
  }

  /* Прием сообщения
     Может прийти error with body
     Ошибку обрабатывает пусть контекст
  */
  Message receiveMessage(xmpp.Message msg) {
    Message newMsg;
    /* Новый формат сообщений в базу */
    if ((msg.from.userAtDomain == me && msg.to.userAtDomain == friend) ||
        (msg.from.userAtDomain == friend && msg.to.userAtDomain == me)) {
      ChatMessageModel chatMessage = ChatMessageModel(
        fuser: msg.from.userAtDomain,
        tuser: msg.to.userAtDomain,
        code: msg.messageId == null ? null : int.parse(msg.messageId),
        type: msg.type.toString(),
        parent: me,
        time: msg.time.toIso8601String(),
        msg: msg.text,
        url: msg.url,
        urlType: msg.urlType,
        id: msg.localId != null ? int.parse(msg.localId) : null,
        sendState: SendStates.sent.index,
      );
      // Если такого сообщения нет,
      // надо впихануть в базень
      insertMessage2DbIfNotExists(chatMessage);

      /* Старый формат сообщений на лету */
      newMsg = ChatMessageModel.convert2Message(chatMessage, me, friend);
    } else {
      // сообщение от другого пользователя,
      // TODO: через JabberConn добавлять его в контакт если нет
    }
    return newMsg;
  }

  /* Функция, вызываемая, когда пользователь
     доскролил до верхнего элемента
     :param index: индекс объекта
     :param count: общее количество объектов
   */
  void loadHistory(int index, int count) {
    if (historyCompleted) {
      return;
    }
    if (count <= index + 1) {
      // Находим самый маленький код в сообщениях
      // и от него получаем историю
      int lastReceivedCode;
      for (Message msg in messageList) {
        if (msg.code == null) {
          continue;
        }
        if (lastReceivedCode == null) {
          lastReceivedCode = msg.code;
        } else if (msg.code < lastReceivedCode) {
          lastReceivedCode = msg.code;
        }
      }
      final String lastCode =
          lastReceivedCode == null ? null : '$lastReceivedCode';
      JabberConn.messageArchiveManager
          .queryLastMessages(jid: buddy.jid, before: lastCode);
    }
  }

  /* Отправка уведомления (на каждый чих) */
  Future<void> sendNotification(String msg, String urlType) async {
    final uri = Uri.parse('https://$JABBER_SERVER$JABBER_NOTIFY_ENDPOINT');
    var response = await http.post(
      uri,
      headers: {
        // HttpHeaders.authorizationHeader: 'Basic xxxxxxx',
        //'Content-Type': 'image/jpeg',
      },
      body: jsonEncode(<String, String>{
        'body': msg,
        'urlType': urlType,
        'toJID': buddy.jid.local,
        'fromJID': JabberConn.connection.fullJid.local,
      }),
    );
    Log.i(TAG,
        'notification response ${response.statusCode}, ${response.body.toString()}');
  }

  /* Отправка сообщения
  *  Отправка изображения (галерея/камера)
  *  Отправка файла
  *  Отправка видео (галерея/камера)
  *  Отправка аудио
  *  */
  Future<Message> sendMessage(String msg,
      {String code, String url, String urlType, File file}) async {
    final chatMessage = ChatMessageModel(
      fuser: me,
      tuser: friend,
      parent: me,
      time: DateTime.now().toIso8601String(),
      msg: msg,
      url: url,
      urlType: urlType,
      filePath: file != null ? file.path : null,
      sendState: SendStates.none.index,
    );
    await chatMessage.insert2Db();
    final newMsg = ChatMessageModel.convert2Message(chatMessage, me, friend);

    // Сразу нельзя засылать с файлом, поэтому надо отложить действие
    if (file == null) {
      JabberConn.messageHandler.sendMessage(buddy.jid, msg,
          url: url, urlType: urlType, localId: chatMessage.id.toString());
      // Отправить уведомление (на каждый чих)
      sendNotification(msg, urlType);
      // Сообщение добавили, необходимо узнать теперь его код и обновить
      getCodesForLastMessages();
    }

    messageList.add(newMsg);
    sortMessageList();
    setStateCallback(
      messageList,
      loggedIn,
    );

    // Очистить черновик сообщения
    ChatDraftModel.dropDraft(me, friend);
    return newMsg;
  }

  /* Узнаем код последнего сообщения,
     вытаскиваем его из базы
     чтобы запросить обновления после него
  */
  Future<void> getCodesForLastMessages() async {
    String afterId;
    final lastMessages = await ChatMessageModel.getByParent(
      me,
      me,
      friend,
      orderBy: 'code DESC',
      limit: 1,
    );
    if (lastMessages.isNotEmpty) {
      afterId = '${lastMessages[0].code}';
    }
    JabberConn.messageArchiveManager
        .queryAfterId(jid: buddy.jid, afterId: afterId, max: '5');
  }

  /* Проверяем состояние экрана авторизации на соответствие JabberConn состоянию */
  @override
  Future<void> checkState() async {
    // Состояние не поменялось
    if (JabberConn.loggedIn == loggedIn && JabberConn.curUser == curUser) {
      return;
    }
    Log.w(TAG, 'STATE CHANGED');
    // TODO: тут надо setState?
    loggedIn = JabberConn.loggedIn;
    curUser = JabberConn.curUser;
  }
}
