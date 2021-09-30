import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/widgets/chat/avatar_widget.dart';

class ChatUserWidget extends StatefulWidget {
  Key key;
  ContactChatModel user;

  ChatUserWidget({
    this.key, // for update widget
    this.user,
  });

  @override
  _ChatUserWidgetState createState() => _ChatUserWidgetState();
}

class _ChatUserWidgetState extends State<ChatUserWidget> {
  final DateFormat formatter = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final containerMsgTextWidth = MediaQuery.of(context).size.width * 0.5;
    final msgTime = (widget.user.time != null && widget.user.time != '-')
        ? formatter.format(DateTime.parse(widget.user.time))
        : '-- --';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, ChatScreen.id, arguments: {
          'user': widget.user,
        });
      },
      child: ListTile(
        leading: Avatar(
          //key: widget.key,
          imgPath: widget.user.getAvatar(),
          isOnline: false, // TODO => онлайн пользователя
        ),
        /*
        leading: CircleAvatar(
          backgroundColor: Colors.grey[100],
          backgroundImage: AssetImage(widget.image),
        ),
         */
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: containerMsgTextWidth,
              child: Text(
                widget.user.getName(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              msgTime,
            ),
          ],
        ),
        subtitle: SizedBox(
          width: containerMsgTextWidth,
          child: Text(
            widget.user.msg != null ? widget.user.msg : widget.user.getName(),
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
