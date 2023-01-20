import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';

import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/chat_header.dart';
import 'package:masterme_chat/widgets/chat/input_widget.dart';
import 'package:masterme_chat/widgets/chat/list_widget.dart';
import 'package:masterme_chat/widgets/chat/message_widget.dart';

import 'package:http/http.dart' as http;
// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

import 'logic/chat_logic.dart';

class ChatScreen extends StatefulWidget {
  static const String id = '/chat_screen/';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String TAG = 'ChatScreen';
  ChatScreenLogic logic;

  // Переменные JabberConn для отслеживания изменения состояния
  bool loggedIn = false;
  int connectionInstanceKey = 0;

  final ScrollController _scrollController = ScrollController();

  bool topReachedByScrollProcessing = false;
  bool topReachedByScrollProcessed = false;

  StreamSubscription messageSubscription;
  StreamSubscription fileUploadSubscription;
  StreamSubscription mamPaginatorSubscription;

  String uploadImagePath;
  String uploadVideoPath;
  String uploadFilePath;
  String uploadAudioPath;

  List<Message> _messageList = [];

  void setUploadImagePath(String path) {
    uploadImagePath = path;
  }

  void setUploadVideoPath(String path) {
    uploadVideoPath = path;
  }

  void setUploadFilePath(String path) {
    uploadFilePath = path;
  }

  void setUploadAudioPath(String path) {
    uploadAudioPath = path;
  }

  @override
  void dispose() {
    JabberConn.receiver = null;
    if (messageSubscription != null) {
      messageSubscription.cancel();
    }
    if (fileUploadSubscription != null) {
      fileUploadSubscription.cancel();
    }
    if (mamPaginatorSubscription != null) {
      mamPaginatorSubscription.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /* Отправка сообщения
  *  Отправка изображения (галерея/камера)
  *  Отправка файла
  *  Отправка видео (галерея/камера)
  *  Отправка аудио
  *  */
  Future<Message> sendMessage(String msg,
      {String code, String url, String urlType, File file}) async {
    if (JabberConn.messageHandler == null) {
      openInfoDialog(context, null, 'Ошибка связи',
          'Связь была потеряна, пожалуйста, перезайдите', 'Понятно');
      return null;
    }
    Message newMsg = await logic.sendMessage(msg,
        code: code, url: url, urlType: urlType, file: file);
    // Dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());
    return newMsg;
  }

  Future<void> uploadFile2Server(getUrl, putUrl) async {
    String fname;
    File file;
    String urlType = 'file';
    final String lastUrlPart = Uri.decodeComponent(putUrl.split('/').last);

    if (uploadImagePath != null &&
        lastUrlPart == uploadImagePath.split('/').last) {
      fname = uploadImagePath.split('/').last;
      file = File(uploadImagePath);
      urlType = 'image';
    } else if (uploadAudioPath != null &&
        lastUrlPart == uploadAudioPath.split('/').last) {
      fname = uploadAudioPath.split('/').last;
      file = File(uploadAudioPath);
      urlType = 'audio';
    } else if (uploadVideoPath != null &&
        lastUrlPart == uploadVideoPath.split('/').last) {
      fname = uploadVideoPath.split('/').last;
      file = File(uploadVideoPath);
      urlType = 'video';
    } else if (uploadFilePath != null &&
        lastUrlPart == uploadFilePath.split('/').last) {
      fname = uploadFilePath.split('/').last;
      file = File(uploadFilePath);
    }
    if (file == null) {
      openInfoDialog(
          context,
          null,
          'Ошибка отправки файла',
          'Ошибка в кодировке $lastUrlPart, попробуйте переименовать файл, используя латинские буквы',
          'Понятно');
      return;
    }

    Message newMessage =
        await sendMessage(fname, url: getUrl, urlType: urlType, file: file);

    final uri = Uri.parse(putUrl);
    var response = await http.put(
      uri,
      headers: {
        // HttpHeaders.authorizationHeader: 'Basic xxxxxxx',
        //'Content-Type': 'image/jpeg',
      },
      body: await file.readAsBytes(),
    );

    if (response.statusCode == 201) {
      // Отложенное действие - отправляем файл, когда загрузится
      if (file != null) {
        JabberConn.messageHandler.sendMessage(
            logic.companion.buddy.jid, newMessage.content,
            url: newMessage.url,
            urlType: newMessage.urlType,
            localId: newMessage.localId.toString());
        // Отправить уведомление (на каждый чих)
        logic.sendNotification(newMessage.content, newMessage.urlType);
        // Сообщение добавили, необходимо узнать теперь его код и обновить
        logic.getCodesForLastMessages();
      }
    } else {
      openInfoDialog(
          context,
          null,
          'Ошибка отправки файла',
          'Не удалось загрузить файл, код ответа сервера ${response.statusCode}, ошибка ${response.body.toString()}',
          'Понятно');
      Log.e(TAG, '[ERROR]: upload $fname failed');
    }
  }

  /* Функция, вызываемая, когда пользователь
     доскролил до верхнего элемента
     :param index: индекс объекта
     :param count: общее количество объектов
   */
  void topReachedByScroll(int index, int count) {
    logic.loadHistory(index, count);
  }

  // Обновление состояния
  void setStateCallback(List<Message> allMessages, bool loggedInVar) {
    setState(() {
      _messageList = allMessages;
      loggedIn = loggedInVar;
    });
    if (loggedIn) {
      listenStreams();
    }
  }

  /* Слушаем подписки */
  Future<void> listenStreams() async {
    if (connectionInstanceKey == JabberConn.instanceKey) {
      return;
    }
    // message subscription
    if (messageSubscription != null) {
      messageSubscription.cancel();
      Log.d(TAG, 'messageSubscription cancel and new');
    } else {
      Log.d(TAG, 'messageSubscription new');
    }
    messageSubscription = JabberConn.messagesStream.listen((xmpp.Message msg) {
      logic.parseReceivedMessage(msg);
    });
    // file subscription
    if (fileUploadSubscription != null) {
      fileUploadSubscription.cancel();
      Log.d(TAG, 'fileUploadSubscription cancel and new');
    } else {
      Log.d(TAG, 'fileUploadSubscription new');
    }
    fileUploadSubscription =
        JabberConn.fileUploadManager.fileUploadStream.listen((stanza) {
      var slot = stanza.getChild('slot');
      if (slot != null &&
          slot.getNameSpace() == JabberConn.fileUploadManager.formType) {
        final String getUrl = slot.children
            .firstWhere((element) => element.name == 'get')
            .getAttribute('url')
            .value;
        final String putUrl = slot.children
            .firstWhere((element) => element.name == 'put')
            .getAttribute('url')
            .value;
        uploadFile2Server(getUrl, putUrl);
      }
    });
    // mam subscription
    if (mamPaginatorSubscription != null) {
      mamPaginatorSubscription.cancel();
      Log.d(TAG, 'mamPaginatorSubscription cancel and new');
    } else {
      Log.d(TAG, 'mamPaginatorSubscription new');
    }
    mamPaginatorSubscription = JabberConn
        .messageArchiveManager.mamPaginatorStream
        .listen((Map<String, String> event) {
      logic.mamPaginator(event);
    });
    // update connectionInstanceKey
    connectionInstanceKey = JabberConn.instanceKey;
  }

  @override
  void initState() {
    logic = ChatScreenLogic(setStateCallback: setStateCallback);
    listenStreams();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logic.parseArguments(context);
    logic.loadAllMessages();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: SafeArea(
          child: ChatHeaderWidget(
            contact: logic.companion,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Flexible(
                  child: ChatList(
                    children: _messageList,
                    scrollController: _scrollController,
                    topReachedByScroll: topReachedByScroll,
                  ),
                ),
                ChatInputWidget(
                  onSend: sendMessage,
                  onPickImage: setUploadImagePath,
                  onPickFile: setUploadFilePath,
                  onPickVideo: setUploadVideoPath,
                  onPickAudio: setUploadAudioPath,
                  login: logic.me,
                  tuser: logic.friend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
