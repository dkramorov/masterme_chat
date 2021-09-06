import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/db/contact_chat_model.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/screens/logic/default_logic.dart';
import 'package:masterme_chat/services/jabber_connection.dart';

// xmpp
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class RosterScreenLogic extends AbstractScreenLogic {
  static const TAG = 'RosterScreenLogic';

  // Отслеживание состояния JabberConn
  bool loggedIn = false;
  UserChatModel curUser;

  bool isDbRosterLoaded = false;

  // Если приехало пуш уведомление,
  // то мы через экран авторизации
  // должны выбрать нужный чат
  String pushFrom;
  String pushTo;

  RosterScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
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
    if (isDbRosterLoaded || JabberConn.connection == null) {
      return null;
    }

    isDbRosterLoaded = true;
    List<ContactChatModel> usersInDB = await ContactChatModel.getAllContacts(
        JabberConn.connection.fullJid.userAtDomain);

    // Обновляем JabberConn.contactsList
    for (ContactChatModel itemInDB in usersInDB) {
      ContactChatModel itemInContactsList = searchInContactsList(itemInDB);
      if (itemInContactsList == null) {
        JabberConn.contactsList.add(itemInDB);
      }
    }
    // Задаем уникальные ключи
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
    for (ContactChatModel itemInContactsList in JabberConn.contactsList){
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

  /* Ищем пользователя в JabberConn.contactsList */
  ContactChatModel searchInContactsList(ContactChatModel contact) {
    for (ContactChatModel itemInContactsList in JabberConn.contactsList) {
      if (itemInContactsList.login == contact.login) {
        return itemInContactsList;
      }
    }
    return null;
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
      ContactChatModel contact = ContactChatModel(
        name: user.name != null ? user.name : user.jid.local,
        login: user.jid.userAtDomain,
        parent: JabberConn.connection.fullJid.userAtDomain,
      );
      ContactChatModel itemInContactsList = searchInContactsList(contact);
      // Если есть в ростере пользователь, тогда надо использовать его
      if (itemInContactsList != null) {
        contact = itemInContactsList;
      }
      add2Roster(contact);
    }
  }

  /* Добавляем в ростер если отсутствует */
  Future<void> add2Roster(ContactChatModel contact) async {
    ContactChatModel itemInContactsList = searchInContactsList(contact);
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

  /* Проверяем состояние экрана */
  @override
  Future<void> checkState() async {

  }

}
