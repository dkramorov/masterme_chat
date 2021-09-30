import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/extensions/vcard_temp/VCard.dart';

class VCardManager {
  static Map<Connection, VCardManager> instances =
      <Connection, VCardManager>{};

  static VCardManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = VCardManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  final Connection _connection;

  VCardManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  final Map<String, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String, Tuple2<IqStanza, Completer>>{};

  final Map<String, VCard> _vCards = <String, VCard>{};

  Future<VCard> getSelfVCard() {
    var completer = Completer<VCard>();
    var iqStanza =
        IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    iqStanza.addChild(vCardElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  Future<VCard> getVCardFor(Jid jid) {
    var completer = Completer<VCard>();
    var iqStanza =
        IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = jid;
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    iqStanza.addChild(vCardElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  /* Обновление vCard,
     vCard обновляется полностью,
     поэтому сразу надо все поля здесь иметь в актуальном состоянии
     https://xmpp.org/extensions/xep-0054.html
     ejabberdctl help set_vcard
     ejabberdctl get_vcard 89148959223 anhel.1sprav.ru NICKNAME
     ejabberdctl set_vcard 89148959223 anhel.1sprav.ru NICKNAME "jocker"
  */
  Future<void> updateVCard(Map<String,String> data) async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    /* Example
    var vCardNameElement = XmppElement();
    vCardNameElement.name = 'NICKNAME';
    vCardNameElement.textValue = 'jocker';
    vCardElement.addChild(vCardNameElement);
    */
    // Добавляем все из словаря data
    data.forEach((k, v) {
        var vCardNewElement = XmppElement();
        vCardNewElement.name = k;
        vCardNewElement.textValue = v;
        vCardElement.addChild(vCardNewElement);
    });
    iqStanza.addChild(vCardElement);
    _connection.writeStanza(iqStanza);
  }

  void _connectionStateProcessor(XmppConnectionState event) {}

  Map<String, VCard> getAllReceivedVCards() {
    return _vCards;
  }

  void _processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (_myUnrespondedIqStanzas[stanza.id] != null) {
        if (stanza.type == IqStanzaType.RESULT) {
          var vCardChild = stanza.getChild('vCard');
          if (vCardChild != null) {
            var vCard = VCard(vCardChild);
            if (stanza.fromJid != null) {
              _vCards[stanza.fromJid.userAtDomain] = vCard;
            } else {
              _vCards[_connection.fullJid.userAtDomain] = vCard;
            }
            unrespondedStanza.item2.complete(vCard);
          }
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedStanza.item2
              .complete(InvalidVCard(stanza.getChild('vCard')));
        }
      }
    }
  }
}
