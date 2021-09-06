import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/data/Jid.dart';



class Item extends Nonza {

  Jid get jid {
    return Jid.fromFullJid(getAttribute('jid')?.value);
  }

  String toString() {
    return '$name $jid';
  }
}
