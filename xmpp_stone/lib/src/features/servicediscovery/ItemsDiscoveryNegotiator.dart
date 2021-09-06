import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'Item.dart';

class ItemsDiscoveryNegotiator extends Negotiator {

  static const String NAMESPACE_DISCO_ITEMS =
      'http://jabber.org/protocol/disco#items';

  bool enabledHttpFileUpload = false;

  static final Map<Connection, ItemsDiscoveryNegotiator> _instances =
  <Connection, ItemsDiscoveryNegotiator>{};

  static ItemsDiscoveryNegotiator getInstance(Connection connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = ItemsDiscoveryNegotiator(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  IqStanza fullRequestStanza;

  StreamSubscription<AbstractStanza> subscription;

  final Connection _connection;

  ItemsDiscoveryNegotiator(this._connection) {
    _connection.connectionStateStream.listen((state) {
      expectedName = 'ItemsDiscoveryNegotiator';
    });
  }

  final StreamController<XmppElement> _errorStreamController =
  StreamController<XmppElement>();

  final List<Item> _supportedItems = <Item>[];

  Stream<XmppElement> get errorStream {
    return _errorStreamController.stream;
  }

  void _parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null &&
          idValue == fullRequestStanza?.getAttribute('id')?.value) {
        _parseFullInfoResponse(stanza);
      } else {
        // Ошибка видимо какая-то, не блокируем, самозавершаемся
        subscription.cancel();
        state = NegotiatorState.DONE;
      }
    }
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return [];
  }

  @override
  void negotiate(List<Nonza> nonza) {
    if (state == NegotiatorState.IDLE) {
      enabledHttpFileUpload = true;
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(_parseStanza);
      _sendItemsDiscoveryRequest();
    } else if (state == NegotiatorState.DONE) {
    }
  }

  void _sendItemsDiscoveryRequest() {
    var request = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    request.fromJid = _connection.fullJid;
    request.toJid = _connection.serverName;
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', NAMESPACE_DISCO_ITEMS));
    request.addChild(queryElement);
    fullRequestStanza = request;
    _connection.writeStanza(request);
  }

  void _parseFullInfoResponse(IqStanza stanza) {
    _supportedItems.clear();
    if (stanza.type == IqStanzaType.RESULT) {
      var queryStanza = stanza.getChild('query');
      if (queryStanza != null) {
        queryStanza.children.forEach((element) {
          if (element is Item) {
            _supportedItems.add(element);
          }
        });
      }
    } else if (stanza.type == IqStanzaType.ERROR) {
      var errorStanza = stanza.getChild('error');
      if (errorStanza != null) {
        _errorStreamController.add(errorStanza);
      }
    }
    subscription.cancel();
    state = NegotiatorState.DONE;
  }

  List<Item> getSupportedItems() {
    return _supportedItems;
  }
}

extension ServiceDiscoveryExtension on Connection {
  List<Item> getSupportedItems() {
    return ItemsDiscoveryNegotiator.getInstance(this).getSupportedItems();
  }
}