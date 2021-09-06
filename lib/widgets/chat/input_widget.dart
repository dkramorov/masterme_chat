import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masterme_chat/db/chat_draft_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/widgets/chat/logic/input_logic.dart';
import 'package:masterme_chat/widgets/chat/record_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatInputWidget extends StatefulWidget {
  final Function onSend;
  final Function onPickImage;
  final Function onPickVideo;
  final Function onPickFile;
  final Function onPickAudio;

  final String login;
  final String tuser;

  ChatInputWidget({
    this.onSend,
    this.onPickImage,
    this.onPickFile,
    this.onPickVideo,
    this.onPickAudio,
    this.login,
    this.tuser,
  });

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final String TAG = 'ChatInputWidget';
  final TextEditingController _textController = TextEditingController();
  String msg;
  bool _sendButtonVisible = false;
  bool _sendAudioRecordVisible = false;
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

  void sendButtonVisibility() {
    setState(() {
      _sendButtonVisible = msg.trim().isEmpty ? false : true;
    });
  }

  /* Показываем виджет с аудио записью */
  void showAudioRecordWidget() {
    setState(() {
      _sendAudioRecordVisible = true;
    });
  }

  void _handleAtachmentPressed(InputWidgetLogic logic) {
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
                      logic.handleImageSelection();
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
                      logic.handleVideoSelection();
                    },
                    label: Text(
                      'Видео',
                      style: textStyle,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.upload_file,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      logic.handleFileSelection();
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
                      logic.handleImageSelection(source: ImageSource.camera);
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
                      logic.handleVideoSelection(source: ImageSource.camera);
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

  /* Загрузчик, вместо выбора файлов */
  Widget buildLoading() {
    if (_sendAudioRecordVisible) {
      return Container();
    }
    return Visibility(
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
    );
  }

  /* Кнопка выбора медиа файлов */
  Widget buildMediaPicker(InputWidgetLogic logic) {
    if (_sendAudioRecordVisible) {
      return Container();
    }
    return Visibility(
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
            _handleAtachmentPressed(logic);
          },
        ),
      ),
    );
  }


  /* Блок для ввода текста сообщения,
     либо контроль записи аудио-файла
  */
  Widget buildInputText(InputWidgetLogic logic) {
    if (_sendAudioRecordVisible) {
      return Expanded(
        child: RecordWidget(handleAudioSelection: logic.handleAudioSelection),
      );
    }
    return Expanded(
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
    );
  }

  /* Запрос прав на запись аудио */
  Future<void> requestAudioPerms() async {
    final storagePerms = await Permission.microphone.status;
    Log.i(TAG, 'microphone perms status $storagePerms');
    if (!storagePerms.isGranted) {
      if (await Permission.microphone.isPermanentlyDenied) {
        openAppSettings();
      } else {
        await [
          Permission.microphone,
        ].request();
      }
    }
  }

  /* Кнопка записи аудио */
  Widget buildAudioRecordButton() {
    if (_sendAudioRecordVisible || _sendButtonVisible) {
      return Container();
    }
    return Visibility(
      visible: !_loading,
      child: SizedBox(
        child: IconButton(
          color: Colors.black54,
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.mic_outlined,
            size: 28.0,
          ),
          onPressed: () {
            setState(() {
              requestAudioPerms();
              _sendAudioRecordVisible = true;
            });;
          },
        ),
      ),
    );
  }

  /* Кнопка отправки сообщения */
  Widget buildSendButton() {
    if (_sendAudioRecordVisible) {
      return SizedBox(
        child: IconButton(
          padding: EdgeInsets.zero,
          color: Colors.black54,
          icon: Icon(
            Icons.cancel,
          ),
          onPressed: () {
            setState(() {
              _sendAudioRecordVisible = false;
            });
          },
        ),
      );
    }
    return Visibility(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Логика на виджет
    InputWidgetLogic logic = InputWidgetLogic(
      context: context,
      onPickFile: widget.onPickFile,
      onPickImage: widget.onPickImage,
      onPickVideo: widget.onPickVideo,
      onPickAudio: widget.onPickAudio,
    );

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
            buildLoading(),
            buildMediaPicker(logic),
            buildInputText(logic),
            buildAudioRecordButton(),
            buildSendButton(),
          ],
        ),
      ),
    );
  }
}
