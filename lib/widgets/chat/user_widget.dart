import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
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

  Widget buildAvatar(String avatar) {
    if (avatar == null) {
      avatar = DEFAULT_AVATAR;
    }
    return Avatar(
      //key: widget.key,
      imgPath: avatar,
      isOnline: false, // TODO => онлайн пользователя
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerMsgTextWidth = MediaQuery.of(context).size.width * 0.40;
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
        leading: FutureBuilder<String>(
            future: widget.user.getAvatar(),
            builder:
                (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return buildAvatar(snapshot.data);
              } else {
                return buildAvatar(null);
              }
            }),
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
