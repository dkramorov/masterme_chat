import 'dart:async';
import 'package:flutter/material.dart';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/add2roster.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/user_widget.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

import 'logic/roster_logic.dart';

class RosterScreen extends StatefulWidget {
  static const String id = '/roster_screen/';

  @override
  _RosterScreenState createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final String TAG = 'RosterScreen';
  RosterScreenLogic logic;

  // Переменные JabberConn для отслеживания изменения состояния
  bool loggedIn = false;
  int connectionInstanceKey = 0;

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

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /* Слушаем состояние подключения */
  Future<void> listenStreams() async {
    if (connectionInstanceKey == JabberConn.instanceKey) {
      return;
    }
    if (presenceSubscription != null) {
      presenceSubscription.cancel();
      Log.d(TAG, 'presenceSubscription cancel and new');
    } else {
      Log.d(TAG, 'presenceSubscription new');
    }
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
    if (rosterSubscription != null) {
      rosterSubscription.cancel();
      Log.d(TAG, 'rosterSubscription cancel and new');
    } else {
      Log.d(TAG, 'rosterSubscription new');
    }

    // TODO: не вызывается при инициализации
    rosterSubscription = JabberConn.rosterManager.rosterStream.listen((event) {
      logic.receiveContacts(event);
    });
    connectionInstanceKey = JabberConn.instanceKey;
  }

  // Переход на чат с пользователем,
  // если было пушь уведомление
  void gotoChatFromPush(List<ContactChatModel> chatUsers) {
    if (logic.pushFrom == null || logic.pushTo == null) {
      return;
    }
    for (ContactChatModel chatUser in chatUsers) {
      String phone = chatUser.login.split('@')[0];
      if (phone == logic.pushFrom && ModalRoute.of(context).isCurrent) {
        Navigator.pushNamed(context, ChatScreen.id, arguments: {
          'user': chatUser,
        });
        return;
      }
    }
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['loggedIn'] != null && state['loggedIn'] != loggedIn) {
        loggedIn = state['loggedIn'];
      }
      if (state['chatUsers'] != null) {
        chatUsers = state['chatUsers'];
        Future.delayed(Duration.zero, () async {
          gotoChatFromPush(state['chatUsers']);
        });
      }
    });
    if (loggedIn) {
      listenStreams();
    }
  }

  @override
  void initState() {
    logic = RosterScreenLogic(setStateCallback: setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logic.parseArguments(context);
    logic.loadChatUsers();

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
              logic.dropActionFromUI(item);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} удален из контактов')));
            },
            child: ChatUserWidget(
              key: item.key == null ? UniqueKey() : item.key,
              user: item,
              /*
              name: item.name != null ? item.name : '',
              messageText: item.msg != null ? item.msg : item.login,
              image: item.getAvatar(),
              time: item.time != null ? item.time : '-',
              isRead: false,
              buddy: item.buddy,
               */
            ),
          );
        },
      ),
    );
  }
}
