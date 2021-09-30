import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/screens/add2roster.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/my_user.dart';
import 'package:masterme_chat/widgets/chat/user_widget.dart';

class TabRosterView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;

  TabRosterView({
    this.pageController,
    this.setStateCallback,
    this.userData,
  });

  @override
  _TabRosterViewState createState() => _TabRosterViewState();
}

class _TabRosterViewState extends State<TabRosterView> {
  static const TAG = 'TabRosterView';

  static const _SEARCH_ICON = 'assets/svg/bp_search_icon.svg';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildView() {
    final _hmeInputTextStyle = Theme.of(context).textTheme.subtitle2;
    // Можно еще margin учесть
    final _halfWidth = MediaQuery.of(context).size.width * 0.4;

    return Column(
      children: [
        SIZED_BOX_H20,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                widget.setStateCallback({
                  'setPageview': 3,
                });
              },
              child: MyUser(
                label: JabberConn.curUser != null
                    ? 'Я, ${JabberConn.curUser.getName()}'
                    : '',
                imgPath: JabberConn.curUser != null ? JabberConn.curUser.getPhoto() : null,
                isReady: JabberConn.curUser != null ? true : false,
                isOnline: JabberConn.loggedIn,
                labelWidth: _halfWidth,
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result =
                    await Navigator.pushNamed(context, Add2RosterScreen.id);
                if (result != null && result) {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    JabberConn.rosterManager.queryForRoster();
                  });
                }
              },
              child: MyUser(
                label: 'Добавить контакт',
                imgPath: 'assets/avatars/add_contact.png',
                isOnline: null,
                labelWidth: _halfWidth,
              ),
            ),
          ],
        ),
        SIZED_BOX_H20,
        Container(
          margin: PAD_SYM_H20,
          padding: PAD_SYM_H20,
          alignment: Alignment.centerLeft,
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: kBackgroundLightColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kShadowColor,
                offset: Offset(0, 10),
                blurRadius: 20,
              )
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                _SEARCH_ICON,
                height: 16,
              ),
              SIZED_BOX_W20,
              Expanded(
                child: FocusScope(
                  child: TextField(
                    autofocus: false,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.name,
                    style: _hmeInputTextStyle,
                    expands: true,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Поиск...',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Обязательно в Expanded,
        // иначе будет не влазить
        Expanded(
          child: buildContacts(context),
        ),
      ],
    );
  }

  String formatTime(String time) {
    return time.substring(time.length - 2);
  }

  ListView buildContacts(BuildContext context) {
    final chatUsers = JabberConn.contactsList;
    return ListView.builder(
      itemCount: chatUsers.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        vertical: 15,
      ),
      itemBuilder: (context, index) {
        final item = chatUsers[index];
        return Dismissible(
          key: UniqueKey(),
          background: Container(color: Colors.red),
          onDismissed: (direction) {
            widget.setStateCallback({'dropActionFromUI': item});
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} удален из контактов')));
          },
          child: ChatUserWidget(
            key: item.key == null ? UniqueKey() : item.key,
            user: item,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: buildView(),
      ),
    );
  }
}
