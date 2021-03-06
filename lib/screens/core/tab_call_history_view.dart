import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/db/user_history_model.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/screens/call.dart';
import 'package:masterme_chat/screens/logic/history_logic.dart';
import 'package:masterme_chat/services/sip_connection.dart';
import 'package:masterme_chat/widgets/companies/company_logo.dart';

class TabCallHistoryView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;

  // Т/к виджет будет пересоздаваться из root_wizard_screen
  // надо сразу оттуда передавать данные по curUser & loggedIn
  UserChatModel curUser;
  bool loggedIn = false;

  TabCallHistoryView(
      {this.pageController, this.setStateCallback, this.userData});

  @override
  _TabCallHistoryViewState createState() => _TabCallHistoryViewState();
}

class _TabCallHistoryViewState extends State<TabCallHistoryView> {
  static const TAG = 'TabCallView';
  List<UserHistoryModel> history = [];
  HistoryScreenLogic logic;

  final DateFormat formatter = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    logic = HistoryScreenLogic(setStateCallback: setStateCallback);
    logic.loadHistory();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void deactivate() {
    logic.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['history'] != null) {
        history = state['history'];
      }
    });
  }

  Widget buildIcon(UserHistoryModel item) {
    if (item.company != null) {
      return CompanyLogoWidget(item.company);
    }
    return Icon(
      Icons.phone_forwarded,
      size: 40.0,
      color: Colors.black54,
    );
  }

  ListView buildHistory() {
    final containerMsgTextWidth = MediaQuery.of(context).size.width * 0.5;
    return ListView.builder(
      itemCount: history.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        vertical: 15,
      ),
      itemBuilder: (context, index) {
        final item = history[history.length - index - 1];
        final duration = SipConnection.calcCallTime(
            item.duration != null ? item.duration : 0);
        return Dismissible(
          key: UniqueKey(),
          background: Container(color: Colors.red),
          onDismissed: (direction) {},
          child: GestureDetector(
            onTap: () {
              if (item.company != null) {
                Navigator.pushNamed(context, CallScreen.id, arguments: {
                  'curPhoneStr': item.dest,
                  'curCompany': item.company,
                });
              } else {
                widget.setStateCallback({
                  'setPageview': 2,
                  'phoneFromHistory': item.dest,
                });
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 5),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[300],
                    offset: Offset(-2, 0),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  child: buildIcon(item),
                  width: 60,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    item.company != null
                        ? Text(
                            item.company.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18.0,
                            ),
                          )
                        : Container(),
                    Text(
                      phoneMaskHelper(item.dest),
                      style: TextStyle(
                        fontSize: 19.0,
                      ),
                    ),
                  ],
                ),
                subtitle: SizedBox(
                  width: containerMsgTextWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        formatter.format(DateTime.parse(item.time)),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Icon(
                        Icons.access_time,
                        size: 13.0,
                      ),
                      SizedBox(
                        width: 5.0,
                      ),
                      Text(duration),
                    ],
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PAD_SYM_H10,
      child: history.isNotEmpty
          ? buildHistory()
          : Center(
              child: Text(
                'История пуста',
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
    );
  }
}
