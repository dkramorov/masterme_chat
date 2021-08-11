import 'dart:async';
import 'package:flutter/material.dart';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/add2roster.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/user_widget.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class RosterScreen extends StatefulWidget {
  static const String id = '/roster_screen/';

  @override
  _RosterScreenState createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final String TAG = 'RosterScreen';
  xmpp.MessageHandler messageHandler;

  StreamSubscription presenceSubscription;
  StreamSubscription rosterSubscription;

  List<ContactChatModel> chatUsers = [];

  @override
  void dispose() {
    if (presenceSubscription != null) {
      presenceSubscription.cancel();
    }
    if (rosterSubscription != null) {
      rosterSubscription.cancel();
    }
    super.dispose();
  }

  /* Добавляем в ростер если отсутствует */
  Future<void> add2Roster(ContactChatModel contact) async {
    final String me = JabberConn.connection.fullJid.userAtDomain;
    final ContactChatModel analog = await ContactChatModel.getByLogin(me, contact.login);
    if (analog == null) {
      contact.insert2Db();
    }
  }

  /* Удаление из ростера */
  Future<void> dropFromRoster(ContactChatModel contact) async {
    contact.delete2Db();
  }

  @override
  void initState() {
    super.initState();

    presenceSubscription =
        JabberConn.presenceManager.subscriptionStream.listen((streamEvent) {
      Log.i(
          TAG,
          'SUBSCRIPTION STREAM ' +
              streamEvent.jid.fullJid +
              ' ' +
              streamEvent.type.toString());
      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
        JabberConn.presenceManager.acceptSubscription(streamEvent.jid);
        Log.i(TAG, 'SUBSCRIPTION ACCEPTED' + streamEvent.jid.userAtDomain);
      }
    });

    rosterSubscription = JabberConn.rosterManager.rosterStream.listen((event) {
      List<ContactChatModel> newChatUsers = [];
      for (xmpp.Buddy user in event) {
        ContactChatModel contact = ContactChatModel(
          name: user.name != null ? user.name : user.jid.local,
          login: user.jid.userAtDomain,
          parent: JabberConn.connection.fullJid.userAtDomain,
        );
        newChatUsers.add(contact);
        bool inList = false;
        for (ContactChatModel item in chatUsers) {
          if (item.login == contact.login) {
            inList = true;
          }
        }
        if (!inList) {
          // В списке чувак отсутствует - добавляем
          setState(() {
            chatUsers.add(contact);
          });
          add2Roster(contact);
        }
      }
      JabberConn.contactsList = newChatUsers;
      if (!mounted) return;
      /*
      setState(() {
        chatUsers = newChatUsers;
      });
       */
    });
    loadChatUsers();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> loadChatUsers() async {
    final List<ContactChatModel> contacts = await ContactChatModel.getAllContacts(JabberConn.connection.fullJid.userAtDomain);
    setState(() {
      chatUsers = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        tooltip: 'Добавление контакта',
        child: Icon(
          Icons.add,
        ),
        backgroundColor: PRIMARY_BG_COLOR,
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, Add2RosterScreen.id);
          if (result != null && result) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              JabberConn.rosterManager.queryForRoster();
            });
          }
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_sharp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    'Контакты',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    JabberConn.clear();
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Выход',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
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
              JabberConn.rosterManager.removeRosterItem(item.buddy);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} удален из контактов')));
              dropFromRoster(item);
              setState(() {
                chatUsers.removeAt(index);
              });
            },
            child: ChatUserWidget(
              name: item.name != null ? item.name : '',
              messageText: item.msg != null ? item.msg : item.login,
              image:
                  item.avatar != null ? item.avatar : 'assets/avatars/user.png',
              time: item.time != null ? item.time : '-',
              isRead: false,
              buddy: item.buddy,
            ),
          );
        },
      ),
    );
  }
}
