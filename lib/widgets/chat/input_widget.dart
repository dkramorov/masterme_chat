import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masterme_chat/db/chat_draft_model.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatInputWidget extends StatefulWidget {
  final Function onSend;
  final Function onPickImage;
  final Function onPickVideo;
  final Function onPickFile;

  final String login;
  final String tuser;

  ChatInputWidget({
    this.onSend,
    this.onPickImage,
    this.onPickFile,
    this.onPickVideo,
    this.login,
    this.tuser,
  });

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  String msg;
  bool _sendButtonVisible = false;
  bool _loading = false;

  /* Переменные для modalBottomSheet */
  final textStyle = TextStyle(fontSize: 17.0);
  final modalBottomSheetHeight = 250.0;

  @override
  void initState() {
    super.initState();
    loadDraft();
  }

  @override
  void dispose() {
    if (_textController.text.isNotEmpty) {
      ChatDraftModel.setDraft(widget.login, widget.tuser, _textController.text);
    }
    _textController.dispose();
    super.dispose();
  }

  Future<void> loadDraft() async {
    final draft = await ChatDraftModel.getDraft(widget.login, widget.tuser);
    if (draft != null) {
      setState(() {
        msg = draft.msg;
        _textController.text = msg;
      });
    }
  }

  void permissionsErrorDialog(String permDesc) {
    // Пока глушим диалог, а то хрен опубликуешь
    // TODO: обыграть по-другому
    if (Platform.isIOS) {
      return;
    }
    openInfoDialog(context, () {
      openAppSettings();
    },
        'Нет доступа к $permDesc',
        'Вы не дали разрешение на использование $permDesc.\n' +
            'Пожалуйста, добавьте разрешение в настройках.\n' +
            'Сейчас мы откроем настройки приложения',
        'Понятно');
  }

  void sendButtonVisibility() {
    setState(() {
      _sendButtonVisible = msg.trim().isEmpty ? false : true;
    });
  }

  void _handleImageSelection({ImageSource source = ImageSource.gallery}) async {
    /* Загрузка изображения */
    PickedFile result;
    try {
      result = await ImagePicker().getImage(
        source: source,
      );
    } catch (err) {
      permissionsErrorDialog('фото');
      return;
    }

    if (result != null) {
      final imageName = result.path.split('/').last;
      final bytes = await result.readAsBytes();
      final size = bytes.length;
      /*
      final image = await decodeImageFromList(bytes);
      final uri = result.path;
      final width = image.width.toDouble();
      final height = image.height.toDouble();
       */
      setState(() {
        _loading = true;
      });
      JabberConn.fileUploadManager.queryRequestSlot(imageName, size);
      await widget.onPickImage(result.path);
      setState(() {
        _loading = false;
      });
    } else {
      // User canceled the picker
    }
  }

  void _handleVideoSelection({ImageSource source = ImageSource.gallery}) async {
    /* Загрузка видео файла */
    PickedFile result;
    try {
      result = await ImagePicker().getVideo(
        source: source,
      );
    } catch (err) {
      permissionsErrorDialog('видео');
      return;
    }

    if (result != null) {
      final videoName = result.path.split('/').last;
      final bytes = await result.readAsBytes();
      final size = bytes.length;

      setState(() {
        _loading = true;
      });
      JabberConn.fileUploadManager.queryRequestSlot(videoName, size);
      await widget.onPickVideo(result.path);
      setState(() {
        _loading = false;
      });
    } else {
      // User canceled the picker
    }
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final fileName = result.files.single.name;
      final size = result.files.single.size;
      final path = result.files.single.path ?? '';

      JabberConn.fileUploadManager.queryRequestSlot(fileName, size);
      await widget.onPickFile(path);
      setState(() {
        _loading = false;
      });
    } else {
      // User canceled the picker
    }
  }

  void _handleAudioSelection() async {
    /* Отправка голосового сообщения */
  }

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: modalBottomSheetHeight,
          color: Color(0xff737373),
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextButton.icon(
                    icon: Icon(
                      Icons.image_outlined,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleImageSelection();
                    },
                    label: Text(
                      'Фото',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.video_collection,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleVideoSelection();
                    },
                    label: Text(
                      'Видео',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.mic_none_outlined,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleAudioSelection();
                    },
                    label: Text(
                      'Аудио-сообщение',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.upload_file,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleFileSelection();
                    },
                    label: Text(
                      'Файл',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleImageSelection(source: ImageSource.camera);
                    },
                    label: Text(
                      'Фото с камеры',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.video_call,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleVideoSelection(source: ImageSource.camera);
                    },
                    label: Text(
                      'Видео с камеры',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.close,
                    ),
                    onPressed: () => Navigator.pop(context),
                    label: Text(
                      'Отмена',
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _query = MediaQuery.of(context);

    return Material(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      color: Colors.grey.shade200,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24 + _query.padding.left,
          20,
          24 + _query.padding.right,
          20 + _query.viewInsets.bottom + _query.padding.bottom,
        ),
        child: Row(
          children: [
            Visibility(
              visible: _loading,
              child: Container(
                height: 24,
                width: 24,
                child: const CircularProgressIndicator(
                  backgroundColor: Colors.transparent,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    //Color(0xffffffff),
                    Colors.black54,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !_loading,
              child: SizedBox(
                child: IconButton(
                  color: Colors.black54,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.attach_file,
                    size: 28.0,
                  ),
                  onPressed: () {
                    _handleAtachmentPressed();
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration.collapsed(
                    hintStyle: TextStyle(
                      //color: Color(0x80ffffff),
                      color: Colors.black54,
                    ),
                    hintText: 'Ваше сообщение...',
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(
                    //color: Color(0xffffffff),
                    color: Colors.black,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    msg = value;
                    sendButtonVisibility();
                  },
                ),
              ),
            ),
            Visibility(
              visible: _sendButtonVisible,
              child: SizedBox(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  color: Colors.black54,
                  icon: FaIcon(
                    FontAwesomeIcons.paperPlane,
                  ),
                  onPressed: () {
                    widget.onSend(msg.trim());
                    _textController.clear();
                    msg = '';
                    sendButtonVisibility();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
