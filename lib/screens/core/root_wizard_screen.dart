import 'dart:async';

import 'package:flutter/material.dart';

import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/dialogs.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/auth/auth.dart';
import 'package:masterme_chat/screens/call.dart';
import 'package:masterme_chat/screens/chat.dart';
import 'package:masterme_chat/screens/core/tab_call_history_view.dart';
import 'package:masterme_chat/screens/core/tab_companies_view.dart';
import 'package:masterme_chat/screens/core/tab_home_view.dart';
import 'package:masterme_chat/screens/core/tab_profile_view.dart';
import 'package:masterme_chat/screens/core/tab_roster_view.dart';
import 'package:masterme_chat/screens/logic/login_logic.dart';
import 'package:masterme_chat/screens/logic/roster_logic.dart';
import 'package:masterme_chat/services/call_keeper.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/services/push_manager.dart';
import 'package:masterme_chat/services/update_manager.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info_plus/package_info_plus.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class RootScreen extends StatefulWidget {
  static const String id = '/';

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  static const TAG = 'RootScreen';
  bool loading = false;
  int connectionInstanceKey = 0;
  Map<String, dynamic> userData = {};

  final Duration _durationPageView = Duration(milliseconds: 500);
  final Curve _curvePageView = Curves.easeInOut;

  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: false,
  );

  LoginScreenLogic loginLogic;
  RosterScreenLogic rosterLogic;

  StreamSubscription pushSubscription;
  StreamSubscription connectionSubscription;
  StreamSubscription presenceSubscription;
  StreamSubscription rosterSubscription;

  bool askPermsPhoneAccountsOpened = false;

  int _pageIndex = 0;
  String title = NavigationData.nav[0]['title'];

  UserChatModel curUser;
  bool loggedIn = false;

  Future<void> init() async {
    final PushNotificationsManager pushManager = PushNotificationsManager();
    await pushManager.init();
    JabberConn.healthcheck();
    UpdateManager().init();
    _initPackageInfo();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    init();
    loginLogic = LoginScreenLogic(setStateCallback: setStateCallback);
    rosterLogic = RosterScreenLogic(setStateCallback: setStateCallback);
    checkUserInDb(loginLogic);
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
    loginLogic.deactivate();
    rosterLogic.deactivate();
  }

  @override
  void dispose() {
    super.dispose();

    loginLogic.dispose();
    rosterLogic.dispose();

    if (pushSubscription != null) {
      pushSubscription.cancel();
    }
    if (connectionSubscription != null) {
      connectionSubscription.cancel();
    }
    if (presenceSubscription != null) {
      presenceSubscription.cancel();
    }
    if (rosterSubscription != null) {
      rosterSubscription.cancel();
    }
    _pageController.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    JabberConn.appVersion = info.version + '+' + info.buildNumber;
  }

  setPageview(int index, {gotoInvisible: false}) {
    if (!gotoInvisible) {
      setState(() {
        _pageIndex = index;
      });
    }
    _pageController.animateToPage(index,
        curve: _curvePageView, duration: _durationPageView);
  }

  Future<void> listenRosterStream() async {
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

    rosterSubscription = JabberConn.rosterManager.rosterStream.listen((event) {
      rosterLogic.receiveContacts(event);
    });
  }

  Future<void> openChat(ContactChatModel user) async {
    if (ModalRoute.of(context).isCurrent) {
      // ??????????????????????, ??????????
      // setState() or markNeedsBuild called during build
      Future.delayed(Duration.zero, () async {
        Navigator.pushNamed(context, ChatScreen.id, arguments: {
          'user': user,
        });
      });
    }
  }

  /* ?????????????? ?????????????????? ?????????????????????? */
  Future<void> listenConnectionStream() async {
    if (pushSubscription == null) {
      // ?????????????????????????? ???? ????????
      pushSubscription = JabberConn.pushStream.listen((event) {
        // 89148959223=>89999999999
        String fromUser = event.split('=>')[0];
        for (ContactChatModel user in JabberConn.contactsList) {
          if (user.login.contains(fromUser)) {
            openChat(user);
          }
        }
      });
    }

    if (connectionSubscription != null) {
      if (connectionInstanceKey != JabberConn.instanceKey) {
        connectionSubscription.cancel();
        Log.d(TAG, 'connectionSubscription cancel');
      } else {
        Log.d(TAG, 'connectionSubscription exists');
        return;
      }
    }
    Log.d(TAG, 'connectionSubscription new');
    connectionInstanceKey = JabberConn.instanceKey;

    connectionSubscription = JabberConn.connectionStream.listen((event) {
      if (event == xmpp.XmppConnectionState.Ready) {
        // ?????????????????????????? ???? ????????????, ?????? ???????????? ????????????????????????
        listenRosterStream();

        // ???????? ???? ???? AuthScreen,
        // ?? ?????? ?? ???????? ?????????? ?? ???? ???? ????????????????????????
        // ???? curUser ?????????? null,
        // ???????????? ?????? ?????? ?????????????????? ?????????????????? ?????????????????????? ?? AuthScreen

        // ???????? ???? ???????????????????????? ?? ???????? ??????????????????
        if (curUser != null) {
          loginLogic
              .authorizationSuccess(curUser.login, curUser.passwd)
              .then((success) {
            rosterLogic.loadChatUsers();
          });
        }

        loginLogic.checkState();
      } else if (event == xmpp.XmppConnectionState.AuthenticationFailure) {
        if (ModalRoute.of(context).isCurrent) {
          openInfoDialog(context, () {
            loginLogic.closeHUD();
            Navigator.pushNamed(context, AuthScreen.id);
          }, '???????????? ??????????????????????', '???????????????????????? ?????????? ?????? ????????????', '??????????????');
        }
        loginLogic.checkState();
      } else if (event == xmpp.XmppConnectionState.ForcefullyClosed) {
        // ?????????? ?????????????? ???? ????????????
        loginLogic.closeHUD();
        loginLogic.checkState();
      }
    });
  }

  /* ???????????????????? ?????? ??????????, ?????? ?????????????????????? ?? ??????????????????????
     ???????????? ????????,
     ???????????? ?????? ?????? JabberConn.curUser ?????????????? ??????????
  */
  Future<void> checkUserInDb(LoginScreenLogic logic) async {
    UserChatModel user = await logic.userFromDb();
    if (user == null) {
      Log.d(TAG, 'userFromDb is null, redirect to AuthScreen');
      Navigator.pushNamed(context, AuthScreen.id);
    } else {
      setState(() {
        curUser = user;
      });
      if (!JabberConn.loggedIn) {
        logic.authorization(curUser.login, curUser.passwd);
      }
    }
  }

  void setStateCallback(Map<String, dynamic> newState) {
    setState(() {
      if (newState['loading'] != null && newState['loading'] != loading) {
        loading = newState['loading'];
      }
      if (newState['loggedIn'] != null && newState['loggedIn'] != loggedIn) {
        loggedIn = newState['loggedIn'];
      }
      if (newState['curUser'] != null && newState['curUser'] != curUser) {
        curUser = newState['curUser'];
      }
      if (newState['chatUsers'] != null) {
        Future.delayed(Duration.zero, () async {
          gotoChatFromPush(newState['chatUsers']);
        });
      }
    });
    if (newState['listenConnectionStream'] != null) {
      listenConnectionStream();
    }
    if (newState['dropActionFromUI'] != null) {
      rosterLogic.dropActionFromUI(newState['dropActionFromUI']);
    }
    // ??????????????, ?????????????? ?????????????? ???? ?????????? ????????????
    if (newState['phoneFromHistory'] != null) {
      userData['phoneFromHistory'] = newState['phoneFromHistory'];
    }
    if (newState['setPageview'] != null) {
      int pind = newState['setPageview'];
      bool gotoInvisible = false;
      if (pind >= 5) {
        gotoInvisible = true;
      }
      setPageview(pind, gotoInvisible: gotoInvisible);
    }
  }

  // ?????????????? ???? ?????? ?? ??????????????????????????,
  // ???????? ???????? ???????? ??????????????????????
  void gotoChatFromPush(List<ContactChatModel> chatUsers) {
    if (rosterLogic.pushFrom == null || rosterLogic.pushTo == null) {
      return;
    }
    for (ContactChatModel chatUser in chatUsers) {
      String phone = chatUser.login.split('@')[0];
      if (phone == rosterLogic.pushFrom && ModalRoute.of(context).isCurrent) {
        Navigator.pushNamed(context, ChatScreen.id, arguments: {
          'user': chatUser,
        });
        return;
      }
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      title = NavigationData.nav[page]['title'];
    });
  }

  @override
  Widget build(BuildContext context) {
    listenConnectionStream();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: SafeArea(
          /* builder ?????? ?????????? ???? ??????????, ?? ?????? ?????????????????? ??????????????
          child: PageView.builder(
            itemCount: 4,
            itemBuilder: _pageViewBuilder,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: NeverScrollableScrollPhysics(),
          ),
          */

          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: NeverScrollableScrollPhysics(),
            children: [
              //TabCompaniesView(
              TabHomeView(
                pageController: _pageController,
                setStateCallback: setStateCallback,
                userData: userData,
              ),
              TabRosterView(
                pageController: _pageController,
                setStateCallback: setStateCallback,
                userData: userData,
              ),
              /* ?? ?????????????? ?? ?????????????????? ?????????? */
              CallScreen(
                pageController: _pageController,
                setStateCallback: setStateCallback,
                userData: userData,
                inScaffold: false,
              ),
              TabCallHistoryView(
                pageController: _pageController,
                setStateCallback: setStateCallback,
                userData: userData,
              ),
              TabProfileView(
                pageController: _pageController,
              ),
              TabCompaniesView(
                pageController: _pageController,
                setStateCallback: setStateCallback,
                userData: userData,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
        child: SizedBox(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _pageIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: kOutSideDateColor,
            backgroundColor: Colors.green,
            // ???????????????????? ?????????????? ?? ????????????????
            //showSelectedLabels: false,
            //showUnselectedLabels: false,
            elevation: 0,
            onTap: (index) {
              setPageview(index);
              setState(() => _pageIndex = index);
            },
            items: NavigationData.nav
                .where((navItem) => navItem['hide'] == null) // ???????????? ??????????????????
                .map(
                  (navItem) => BottomNavigationBarItem(
                    icon: Icon(
                      navItem['icon'],
                    ),
                    tooltip: navItem['tooltip'],
                    label: navItem['label'],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationData {
  static List<dynamic> nav = [
    {
      'icon': Icons.format_list_bulleted,
      'index': 0,
      'label': '??????????????',
      'tooltip': '??????????????',
      'title': '?????????????? ????????????????',
    },
    {
      'icon': Icons.forum,
      'index': 1,
      'label': '??????',
      'tooltip': '??????',
      'title': '??????',
    },
    {
      'icon': Icons.dialpad,
      'index': 2,
      'label': '??????????????????',
      'tooltip': '???????????????????? ????????????',
      'title': '???????????????????? ????????????',
    },
    {
      'icon': Icons.phone_forwarded,
      'index': 3,
      'label': '??????????????',
      'tooltip': '?????????????? ??????????????',
      'title': '?????????????? ??????????????',
    },
    {
      'icon': Icons.account_circle_outlined,
      'index': 4,
      'label': '??????????????',
      'tooltip': '??????????????',
      'title': '?????? ??????????????',
    },
    {
      'icon': Icons.domain,
      'index': 5,
      'label': '??????????????',
      'tooltip': '??????????????',
      'title': '?????????????? ????????????????',
      'hide': true,
    },
  ];
}
