import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/chat.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class ChatUserWidget extends StatefulWidget {
  String name;
  String image;
  String messageText;
  String time;
  bool isRead;
  xmpp.Buddy buddy;

  ChatUserWidget({
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
  @override
  Widget build(BuildContext context) {
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
              widget.time,
            ),
          ],
        ),
        subtitle: Text(widget.messageText),
        trailing: Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}
