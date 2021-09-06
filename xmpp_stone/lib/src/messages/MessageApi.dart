import 'package:xmpp_stone/src/data/Jid.dart';

abstract class MessageApi {
  //void sendMessage(Jid to, String text);
  void sendMessage(Jid to, String text,
      {String url, String urlType, String localId});
}
