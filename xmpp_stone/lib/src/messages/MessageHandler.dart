import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/messages/MessageApi.dart';

class MessageHandler implements MessageApi {
  static Map<Connection, MessageHandler> instances =
      <Connection, MessageHandler>{};

  Stream<MessageStanza> get messagesStream {
    return _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is MessageStanza)
        .map((stanza) => stanza as MessageStanza);
  }

  Stream<IqStanza> get stanzaStream {
    return _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is IqStanza)
        .map((stanza) => stanza as IqStanza);
  }

  static MessageHandler getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = MessageHandler(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  Connection _connection;

  MessageHandler(Connection connection) {
    _connection = connection;
  }

  @override
  void sendMessage(Jid to, String text,
      {String url, String urlType, String localId}) {
    _sendMessageStanza(to, text, url: url, urlType: urlType, localId: localId);
  }

  void _sendMessageStanza(Jid jid, String text,
      {String url, String urlType, String localId}) {
    var stanza =
        MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    stanza.url = url;
    stanza.urlType = urlType;
    stanza.localId = localId;
    _connection.writeStanza(stanza);
  }
}
