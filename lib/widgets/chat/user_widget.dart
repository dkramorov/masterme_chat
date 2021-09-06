import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/chat.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class ChatUserWidget extends StatefulWidget {
  Key key;

  String name;
  String image;
  String messageText;
  String time;
  bool isRead;
  final xmpp.Buddy buddy;

  ChatUserWidget({
    this.key, // for update widget
    this.name,
    this.image,
    this.messageText,
    this.time,
    this.isRead,
    this.buddy,
  });

  @override
  _ChatUserWidgetState createState() => _ChatUserWidgetState();
}

class _ChatUserWidgetState extends State<ChatUserWidget> {
  final DateFormat formatter = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final containerMsgTextWidth = MediaQuery.of(context).size.width * 0.5;
    final msgTime = (widget.time != null && widget.time != '-')
        ? formatter.format(DateTime.parse(widget.time))
        : widget.time;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, ChatScreen.id, arguments: {
          'name': widget.name,
          'image': widget.image,
          'buddy': widget.buddy,
        });
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[100],
          backgroundImage: AssetImage(widget.image),
        ),
        title: Row(
          children: [
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              width: 30.0,
            ),
            Text(
              msgTime,
            ),
          ],
        ),
        subtitle: SizedBox(
          width: containerMsgTextWidth,
          child: Text(
            widget.messageText,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}
