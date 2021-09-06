import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class RequestElement extends XmppElement{
  RequestElement() {
    name = 'request';
  }

  void addX(XElement xElement) {
    addChild(xElement);
  }

  void setXmlns(String xmlns) {
    addAttribute(XmppAttribute('xmlns', xmlns));
  }

}