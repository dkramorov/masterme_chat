/*
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class TestScreen extends StatefulWidget {
  static const String id = '/test_screen/';

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {

  final _user = const types.User(id: '06c33e8b-e835-4736-80f4-63f44b66666c');
  List<types.Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      authorId: _user.id,
      id: _user.id,
      text: message.text,
      timestamp: (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
    );

    _addMessage(textMessage);
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }


  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  //_handleImageSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  //_handleFileSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final message = types.FileMessage(
        authorId: _user.id,
        fileName: result.files.single.name,
        id: Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path ?? ''),
        size: result.files.single.size,
        timestamp: (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
        uri: result.files.single.path ?? '',
      );

      _addMessage(message);
    } else {
      // User canceled the picker
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().getImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final imageName = result.path.split('/').last;

      final message = types.ImageMessage(
        authorId: _user.id,
        height: image.height.toDouble(),
        id: Uuid().v4(),
        imageName: imageName,
        size: bytes.length,
        timestamp: (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    } else {
      // User canceled the picker
    }
  }

  void _handleMessageTap(types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);

    final currentMessage = _messages[index] as types.TextMessage;
    final updatedMessage = currentMessage.copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/test/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TEST',
        ),
      ),
      body: Chat(
        user: _user,
        messages: _messages,
        onSendPressed: _handleSendPressed,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onAttachmentPressed: _handleAtachmentPressed,
        //onMessageTap: _handleMessageTap,
      ),
    );
  }
}
*/