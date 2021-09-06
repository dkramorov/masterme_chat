import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class SetElement extends XmppElement{
  SetElement() {
    name = 'set';
  }

  void setXmlns(String xmlns) {
    addAttribute(XmppAttribute('xmlns', xmlns));
  }
}