import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'package:xmpp_stone/xmpp_stone.dart';

/*
1) достать все контакты с базы (тут есть данные по последнему сообщению)
2) если есть подключение, получить все с сервера (тут нет данных по последнему сообщению)
  2.1) обогатить контакт данными из базени
3) обновить контакты в JabberConn.contactsList
*/

class RosterScreenLogic extends AbstractScreenLogic {
  static const TAG = 'RosterScreenLogic';

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  // Если приехало пуш уведомление,
  // то мы через экран авторизации
  // должны выбрать нужный чат
  String pushFrom;
  String pushTo;

  int curVCardIndex = 0;
  static const int defaultUpdateRosterVCardInterval = 15;
  int updateRosterVCardInterval = defaultUpdateRosterVCardInterval;

  RosterScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      updateNextRosterVCard(); // Не продуктивно
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

  /* Есть интервал и т/к таймер обновляется раз в 2 секунды,
     значит, до обновления одной VCard мы будем ждать 30 секунд
     затем увеличим индекс VCard, чтобы в следующий раз обновить следующую
  */
  Future<void> updateNextRosterVCard() async {
    updateRosterVCardInterval -= 1;
    if (JabberConn.contactsList.length == 0 || !JabberConn.loggedIn) {
      return;
    }
    if (updateRosterVCardInterval < 0) {
      updateRosterVCardInterval = defaultUpdateRosterVCardInterval;
      if (curVCardIndex > JabberConn.contactsList.length - 1) {
        curVCardIndex = 0;
      }

      // Обновляем предыдущую пока получаем следующую
      var allVCards = JabberConn.vCardManager.getAllReceivedVCards();

      allVCards.forEach((login, vCard) {
        for (ContactChatModel prevContact in JabberConn.contactsList) {
          if (login != prevContact.login) {
            continue;
          }
          bool updateNeeded = false;
          if (vCard.fullName != prevContact.name) {
            updateNeeded = true;
          }
          if (vCard.imageByUrl != prevContact.avatarUrl) {
            prevContact.avatarUrl = vCard.imageByUrl;
            prevContact.dowloadAvatar();
          }
          if (updateNeeded) {
            prevContact.updatePartial(prevContact.id, {
              'name': vCard.fullName,
            });
            prevContact.name = vCard.fullName;
            prevContact.key = UniqueKey();
            setStateCallback({'chatUsers': JabberConn.contactsList});
          }
        }
      });

      var nextContact = JabberConn.contactsList[curVCardIndex];
      //Log.d(TAG, 'Time to update VCard with index $curVCardIndex for user ${nextContact.toString()}');
      curVCardIndex += 1;

      JabberConn.vCardManager.getVCardFor(nextContact.buddy.jid);
      //Log.d(TAG, 'ALL RECEIVED VCARDS: ${JabberConn.vCardManager.getAllReceivedVCards()}');
    }
  }

  /* Выход */
  logout() async {
    JabberConn.clear();
    setStateCallback({'loading': false, 'loggedIn': false});
    checkState();
  }

  /* Загружаем пользователей с базени */
  Future<void> loadChatUsers() async {
    // Вызывать будем только раз
    if (JabberConn.connection == null) {
      return null;
    }

    List<ContactChatModel> usersInDB = await ContactChatModel.getAllContacts(
        JabberConn.connection.fullJid.userAtDomain);

    // Обновляем JabberConn.contactsList
    for (ContactChatModel itemInDB in usersInDB) {
      ContactChatModel itemInContactsList =
          JabberConn.searchInContactsList(itemInDB);
      if (itemInContactsList == null) {
        JabberConn.contactsList.add(itemInDB);
      }
    }
    // Задаем уникальные ключи для UI
    for (ContactChatModel user in JabberConn.contactsList) {
      user.key = UniqueKey();
    }
    setStateCallback({'chatUsers': JabberConn.contactsList});
  }

  /* Удаление контакта (действие пользователя через UI) */
  Future<void> dropActionFromUI(ContactChatModel contact) async {
    dropFromRoster(contact);
  }

  /* Удаление из ростера */
  Future<void> dropFromRoster(ContactChatModel contact) async {
    ContactChatModel forDel;
    for (ContactChatModel itemInContactsList in JabberConn.contactsList) {
      if (itemInContactsList.login == contact.login) {
        forDel = itemInContactsList;
        break;
      }
    }
    if (forDel == null) {
      return;
    }
    JabberConn.contactsList.remove(forDel);
    setStateCallback({'chatUsers': JabberConn.contactsList});
    contact.delete2Db();
    JabberConn.rosterManager.removeRosterItem(contact.buddy);
  }

  /* Добавление списка пользователей в ростер
     1) Получение ростера с сервера, весь список
     2) Добавление контакта вручную
     3) Добавление контакта автоматически по сообщению
     Исключаем здесь chatUsers, оставляем только в JabberConn
  */
  Future<void> receiveContacts(List<xmpp.Buddy> contacts) async {
    // Пришел контакт, он уже может быть в JabberConn.contactsList
    for (xmpp.Buddy user in contacts) {
      if (JabberConn.curUser == null) {
        Log.d(TAG, 'receiveContacts failed, because curUser is null\n' +
        'tried to receive ${user.toString()}');
        continue;
      }
      if (user.jid.local == JabberConn.curUser.login) {
        Log.d(TAG, 'do not add self to contacts list');
        continue;
      }

      ContactChatModel contact = ContactChatModel(
        name: user.name != null ? user.name : user.jid.local,
        login: user.jid.userAtDomain,
        parent: JabberConn.connection.fullJid.userAtDomain,
      );
      ContactChatModel itemInContactsList =
          JabberConn.searchInContactsList(contact);
      // Если есть в ростере пользователь, тогда надо использовать его
      if (itemInContactsList != null) {
        contact = itemInContactsList;
      }
      add2Roster(contact);
    }
  }

  /* Добавляем в ростер если отсутствует */
  Future<void> add2Roster(ContactChatModel contact) async {
    ContactChatModel itemInContactsList =
        JabberConn.searchInContactsList(contact);
    if (itemInContactsList == null || itemInContactsList.id == null) {
      final String me = JabberConn.connection?.fullJid?.userAtDomain;
      if (me == null) {
        Log.e('[ERROR] add2Roster', 'me is null');
        return;
      }
      final ContactChatModel itemInDB =
          await ContactChatModel.getByLogin(me, contact.login);
      // В базе чувак отсутствует - добавляем,
      // получаем id
      if (itemInDB == null) {
        await contact.insert2Db();
      }
      // В списке чувак отсутствует - добавляем
      if (itemInContactsList == null) {
        JabberConn.contactsList.add(contact);
        itemInContactsList = contact;
        // Запрашиваем карточку тварыны
        //JabberConn.vCardManager.getVCardFor(contact.buddy.jid);
      }
    }
    itemInContactsList.key = UniqueKey();
    setStateCallback({'chatUsers': JabberConn.contactsList});
  }

  /* Получение аргументов на вьюхе (пушь уведомление) */
  void parseArguments(BuildContext context) {
    // Аргументы доступны только после получения контекста
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) {
      pushFrom = arguments['from'];
      pushTo = arguments['to'];
    }
  }
}
