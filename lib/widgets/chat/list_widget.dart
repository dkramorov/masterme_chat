import 'package:flutter/material.dart';
import 'package:masterme_chat/widgets/chat/message_widget.dart';

class ChatList extends StatefulWidget {

  // Messages that will be shown
  final List<Message> children;

  // ScrollController to be attached in the [ListView]
  final ScrollController scrollController;

  // [ListView] shrinkWrap field
  final bool shrinkWrap;

  // Padding of the list
  final EdgeInsets padding;

  /* Функция, вызываемая, когда пользователь
     доскролил до верхнего элемента
   */
  final Function topReachedByScroll;

  ChatList({
    this.children = const <Message>[],
    this.scrollController,
    this.shrinkWrap = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
    this.topReachedByScroll,
  });

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget build(context) {
    final int childrenLen = widget.children.length;

    final emptyMessageListWidget = SizedBox.expand(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Сообщений нет',
          textAlign: TextAlign.center,
        ),
      ),
    );

    return childrenLen == 0
        ? emptyMessageListWidget
        : SizedBox.expand(
            child: ListView.builder(
              shrinkWrap: widget.shrinkWrap,
              controller: widget.scrollController ?? ScrollController(),
              padding: widget.padding,
              itemCount: childrenLen,
              itemBuilder: (BuildContext buildContext, int index) {
                // Если надо подгружать сообщения,
                // которые выше, вызываем спец. функцию
                if (widget.topReachedByScroll != null) {
                  widget.topReachedByScroll(index, childrenLen);
                }
                Message item = widget.children[childrenLen - index - 1];
                return item;
              },
              reverse: true,
            ),
          );
  }
}
