import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/image_widget.dart';
import 'package:masterme_chat/widgets/chat/file_widget.dart';
import 'package:masterme_chat/widgets/chat/video_message_widget.dart';
import 'package:masterme_chat/widgets/chat/audio_message_widget.dart';

class Message extends StatefulWidget {
  Key key;

  // DateFormat('yyyy-MM-dd');
  final DateFormat formatter = DateFormat('HH:mm');
  final DateFormat formatterDay = DateFormat('dd/MM E');

  final DateTime now = DateTime.now().toLocal();
  // final String time = formatter.format(now);

  // The content to be displayed as a message
  String content;

  // the font-family of the [content].
  final String fontFamily;

  // the font-size of the [content].
  final double fontSize;

  // the text-color of the [content].
  final Color textColor;

  // Controls who is sending or receiving a message.
  // Used to handle in which side of the screen the message
  // will be displayed.
  final OwnerType ownerType;

  // Name to be displayed with the initials.
  // egg.: Higor Lapa will be HL
  final String ownerName;

  // Controls if we should show the owner name inside the avatar
  final bool showOwnerName;

  // Background color of the message
  final Color backgroundColor;

  // Message time
  final DateTime time;

  // Url
  final String url;

  // Url type (image, video, etc)
  final String urlType;

  final String fuser;
  final String tuser;

  // Unique code of message
  // can change during update
  int code;

  // Path for file if local
  File file;

  // db id
  final int localId;
  // Состояние отправки
  final int sendState;

  bool newDay;

  Message({
    this.key, // for update widget
    this.content = '',
    this.time,
    this.newDay = false,
    this.url,
    this.urlType,
    this.code,
    this.fontFamily,
    this.fontSize = 16.0,
    this.textColor,
    this.ownerType = OwnerType.sender,
    this.ownerName,
    this.showOwnerName = true,
    this.backgroundColor,
    this.file,
    this.localId,
    this.fuser,
    this.tuser,
    this.sendState,
  });

  String debugString() {
    return 'Message:\n' +
        '\tcontent=$content\n' +
        '\ttime=$time\n' +
        '\tnewDay=$newDay\n' +
        '\turl=$url\n' +
        '\turlType=$urlType\n' +
        '\tcode=$code\n' +
        '\townerType=${ownerType.toString()}\n' +
        '\townerName=$ownerName\n' +
        '\tfile=$file\n' +
        '\tlocalId=$localId\n' +
        '\tfuser=$fuser\n' +
        '\ttuser=$tuser\n';
  }

  @override
  _MessageState createState() => _MessageState();

}

class _MessageState extends State<Message> implements IMessageWidget {
  final loaderImage = AssetImage('assets/loading/loading_green.gif');
  String messageText;

  @override
  void initState() {
    messageText = widget.content;
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  String get senderInitials {
    if (!widget.showOwnerName) {
      return '';
    }

    if (widget.ownerName == JabberConn.connection?.fullJid?.userAtDomain ||
        widget.ownerName == null ||
        widget.ownerName.isEmpty) return 'Я';

    try {
      if (widget.ownerName.lastIndexOf(' ') == -1) {
        return widget.ownerName[0];
      } else {
        var lastInitial =
            widget.ownerName.substring(widget.ownerName.lastIndexOf(' ') + 1);

        return widget.ownerName[0] + lastInitial[0];
      }
    } catch (e) {
      print(e);
      return 'Я';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.ownerType) {
      case OwnerType.receiver:
        return buildReceiver();
      case OwnerType.sender:
      default:
        return buildSender();
    }
  }

  Container buildNewDay() {
    if (widget.newDay)
      return Container(
        margin: EdgeInsets.only(
          top: 45.0,
          bottom: 5.0,
        ),
        child: Text(
          widget.formatterDay.format(widget.time.toLocal()),
          style: TextStyle(
            fontSize: 18.0,
          ),
        ),
      );
    return Container();
  }

  @override
  Widget buildReceiver() {
    return Column(
      children: [
        buildNewDay(),
        Container(
          padding: EdgeInsets.only(
            top: 15.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildCircleAvatar(),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 3.0,
                        left: 10.0,
                      ),
                      child: Text(
                        widget.time == null
                            ? widget.formatter.format(widget.now)
                            : widget.formatter.format(widget.time.toLocal()),
                      ),
                    ),
                    Bubble(
                      margin: BubbleEdges.fromLTRB(10, 10, 30, 0),
                      stick: true,
                      nip: BubbleNip.leftTop,
                      color: widget.backgroundColor ??
                          Color.fromRGBO(233, 232, 252, 10),
                      alignment: Alignment.topLeft,
                      child: _buildContentText('left'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildSender() {
    return Column(
      children: [
        buildNewDay(),
        Container(
          padding: EdgeInsets.only(
            top: 15.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 3.0,
                        right: 10.0,
                      ),
                      child: Text(
                        widget.time == null
                            ? widget.formatter.format(widget.now)
                            : widget.formatter.format(widget.time.toLocal()),
                      ),
                    ),
                    Bubble(
                      margin: BubbleEdges.fromLTRB(30, 10, 10, 0),
                      stick: true,
                      nip: BubbleNip.rightTop,
                      color: widget.backgroundColor ?? Colors.white,
                      alignment: Alignment.topRight,
                      child: _buildContentText('right'),
                    ),
                  ],
                ),
              ),
              _buildCircleAvatar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentText(String align) {
    Widget child;

    if (widget.url != null) {
      // Изображение
      if (widget.urlType == 'image') {
        child = widget.file != null
            ? ImageMessageWidget(
                child: FadeInImage(
                  image: FileImage(widget.file),
                  placeholder: loaderImage,
                ),
              )
            : ImageMessageWidget(
                child: FadeInImage(
                  image: NetworkImage(
                    widget.url,
                  ),
                  placeholder: loaderImage,
                ),
              );
      } else if (widget.urlType == 'audio') {
        child = AudioMessageWidget(
          file: widget.file,
          url: widget.url,
        );
      } else if (widget.urlType == 'video') {
        child = VideoMessageWidget(
          file: widget.file,
          url: widget.url,
          fname: widget.content,
        );
      } else if (widget.urlType == 'file') {
        child = FileMessageWidget(
          file: widget.file,
          url: widget.url,
          fname: widget.content,
        );
      }
    } else {
      // Текст
      child = Text(
        widget.content,
        style: TextStyle(
            fontSize: widget.fontSize,
            color: widget.textColor ?? Colors.black,
            fontFamily: widget.fontFamily ??
                DefaultTextStyle.of(context).style.fontFamily),
      );
    }
    return Column(
      crossAxisAlignment: align == 'right' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        child,
        widget.ownerType == OwnerType.sender ? Icon(
          Icons.check,
          color: widget.code != null ? Colors.lightGreen : Colors.black12,
          size: 16.0,
        ): SizedBox(),
      ],
    );
  }

  Widget _buildCircleAvatar() {
    return CircleAvatar(
        backgroundColor: PRIMARY_BG_COLOR,
        radius: 15,
        child: Text(
          senderInitials,
          style: TextStyle(fontSize: 15),
        ));
  }
}

abstract class IMessageWidget {
  Widget buildReceiver();
  Widget buildSender();
}

enum OwnerType { receiver, sender }
