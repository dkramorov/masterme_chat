import 'dart:async';
import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

import 'package:xmpp_stone/src/elements/forms/RequestElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ItemsDiscoveryNegotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoveryNegotiator.dart';
import '../../Connection.dart';
import '../../data/Jid.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../../elements/forms/FieldElement.dart';
import '../servicediscovery/Item.dart';

// https://xmpp.org/extensions/xep-0363.html
class HttpFileUploadManager {
  static const TAG = 'HttpFileUploadManager';

  static Map<Connection, HttpFileUploadManager> instances =
      <Connection, HttpFileUploadManager>{};

  static HttpFileUploadManager getInstance(Connection connection) {
    var instance = instances[connection];
    if (instance == null) {
      instance = HttpFileUploadManager(connection);
      instances[connection] = instance;
    }
    return instance;
  }

  Connection _connection;
  int maxFileSize = null;
  String formType = null;

  final Map<String, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String, Tuple2<IqStanza, Completer>>{};
  final StreamController<IqStanza> _fileUploadController =
      StreamController<IqStanza>.broadcast();
  Stream<IqStanza> get fileUploadStream {
    return _fileUploadController.stream;
  }

  bool get enabled =>
      ItemsDiscoveryNegotiator.getInstance(_connection).enabledHttpFileUpload;
  Jid get fileUploadUri {
    /*
<iq from='montague.tld'
    id='step_01'
    to='romeo@montague.tld/garden'
    type='result'>
  <query xmlns='http://jabber.org/protocol/disco#items'>
    <item jid='upload.montague.tld' name='HTTP File Upload' />
    <item jid='conference.montague.tld' name='Chatroom Service' />
  </query>
</iq>
     */
    for (Item item in ItemsDiscoveryNegotiator.getInstance(_connection)
        .getSupportedItems()) {
      if (item.jid.userAtDomain.startsWith('upload.')) {
        return item.jid;
      }
    }
  }

  HttpFileUploadManager(Connection connection) {
    _connection = connection;
    _connection.inStanzasStream.listen(_processStanza);
  }

  void _processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (unrespondedStanza != null) {
        if (stanza.type == IqStanzaType.RESULT) {
          _handleFileUploadResponse(stanza);
        }
      }
    }
  }

  void _handleFileUploadResponse(IqStanza stanza) {
    var query = stanza.getChild('query');
    var slot = stanza.getChild('slot');
    if (query != null &&
        query.getNameSpace() ==
            ServiceDiscoveryNegotiator.NAMESPACE_DISCO_INFO) {
      /*
<x type='result' xmlns='jabber:x:data'>
  <field var='FORM_TYPE' type='hidden'>
    <value>urn:xmpp:http:upload:0</value>
  </field>
  <field var='max-file-size'>
    <value>5242880</value>
  </field>
</x>
      */
      query.children.forEach((child) {
        if (child.name == 'x' && child.getNameSpace() == 'jabber:x:data') {
          if (child.children == null) {
            return;
          }
          child.children.forEach((element) {
            if (element is FieldElement) {
              if (element.varAttr == 'max-file-size') {
                maxFileSize = int.parse(element.value);
              } else if (element.varAttr == 'FORM_TYPE') {
                if (element.value.contains(':') &&
                    element.value.contains('upload')) formType = element.value;
              }
            }
          });
        }
      });
    } else if (slot != null && slot.getNameSpace() == formType) {
      /*
<iq from='upload.montague.tld'
    id='step_03'
    to='romeo@montague.tld/garden'
    type='result'>
  <slot xmlns='urn:xmpp:http:upload:0'>
    <put url='https://upload.montague.tld/4a771ac1-f0b2-4a4a-9700-f2a26fa2bb67/tr%C3%A8s%20cool.jpg'>
      <header name='Authorization'>Basic Base64String==</header>
      <header name='Cookie'>foo=bar; user=romeo</header>
    </put>
    <get url='https://download.montague.tld/4a771ac1-f0b2-4a4a-9700-f2a26fa2bb67/tr%C3%A8s%20cool.jpg' />
  </slot>
</iq>
       */
      XmppElement getUrl = slot.children.firstWhere((element) => element.name == 'get');
      XmppElement putUrl = slot.children.firstWhere((element) => element.name == 'put');
    } else {
      /* TODO: ошибку обработать
<iq from='upload.montague.tld'
    id='step_03'
    to='romeo@montague.tld/garden'
    type='error'>
  <request xmlns='urn:xmpp:http:upload:0'
    filename='très cool.jpg'
    size='23456'
    content-type='image/jpeg' />
  <error type='modify'>
    <not-acceptable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas' />
    <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>File too large. The maximum file size is 20000 bytes</text>
    <file-too-large xmlns='urn:xmpp:http:upload:0'>
      <max-file-size>20000</max-file-size>
    </file-too-large>
  </error>
</iq>

или

<iq from='upload.montague.tld'
    id='step_03'
    to='romeo@montague.tld/garden'
    type='error'>
  <request xmlns='urn:xmpp:http:upload:0'
    filename='très cool.jpg'
    size='23456'
    content-type='image/jpeg' />
  <error type='wait'>
    <resource-constraint xmlns='urn:ietf:params:xml:ns:xmpp-stanzas' />
    <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>Quota reached. You can only upload 5 files in 5 minutes</text>
    <retry xmlns='urn:xmpp:http:upload:0'
      stamp='2017-12-03T23:42:05Z' />
  </error>
</iq>

или

<iq from='upload.montague.tld'
    id='step_03'
    to='romeo@montague.tld/garden'
    type='error'>
  <request xmlns='urn:xmpp:http:upload:0'
     filename='très cool.jpg'
     size='23456'
     content-type='image/jpeg' />
  <error type='auth'>
    <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas' />
    <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>Only premium members are allowed to upload files</text>
  </error>
</iq>
       */
    }
    if (maxFileSize != null && formType != null) {
      _fileUploadController.add(stanza);
    }
  }

  /*
<iq from='romeo@montague.tld/garden'
    id='step_02'
    to='upload.montague.tld'
    type='get'>
  <query xmlns='http://jabber.org/protocol/disco#info'/>
</iq>
   */
  void queryUploadInfo() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = fileUploadUri;
    var query = QueryElement();
    query.setXmlns(ServiceDiscoveryNegotiator.NAMESPACE_DISCO_INFO);
    iqStanza.addChild(query);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }

  /*
<iq from='romeo@montague.tld/garden'
    id='step_03'
    to='upload.montague.tld'
    type='get'>
  <request xmlns='urn:xmpp:http:upload:0'
    filename='très cool.jpg'
    size='23456'
    content-type='image/jpeg' />
</iq>
   */
  void queryRequestSlot(String filename, int size) {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = fileUploadUri;
    var req = RequestElement();
    req.setXmlns(formType);
    req.addAttribute(XmppAttribute('filename', filename));
    req.addAttribute(XmppAttribute('size', size.toString()));
    iqStanza.addChild(req);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }
}

// method for getting module
extension FileUploadModuleGetter on Connection {
  HttpFileUploadManager getFileUploadModule() {
    return HttpFileUploadManager.getInstance(this);
  }
}
