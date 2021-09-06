import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import '../../Connection.dart';
import '../../data/Jid.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../../elements/forms/FieldElement.dart';
import '../../elements/forms/SetElement.dart';

/* https://xmpp.org/extensions/xep-0313.html
   https://xmpp.org/extensions/xep-0059.html
 */
class MessageArchiveManager {
  static const TAG = 'MessageArchiveManager';

  static Map<Connection, MessageArchiveManager> instances =
      <Connection, MessageArchiveManager>{};

  static MessageArchiveManager getInstance(Connection connection) {
    var instance = instances[connection];
    if (instance == null) {
      instance = MessageArchiveManager(connection);
      instances[connection] = instance;
    }
    return instance;
  }

  Connection _connection;

  bool get enabled => MAMNegotiator.getInstance(_connection).enabled;

  bool get hasExtended => MAMNegotiator.getInstance(_connection).hasExtended;

  bool get isQueryByDateSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByDateSupported;

  bool get isQueryByIdSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByIdSupported;

  bool get isQueryByJidSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByJidSupported;

  final Map<String, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String, Tuple2<IqStanza, Completer>>{};

  final StreamController<Map<String, String>> _mamPaginatorController =
      StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get mamPaginatorStream {
    return _mamPaginatorController.stream;
  }

  MessageArchiveManager(Connection connection) {
    _connection = connection;
    _connection.inStanzasStream.listen(_processStanza);
  }

  void _processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      final unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (unrespondedStanza != null) {
        if (stanza.type == IqStanzaType.RESULT) {
          _handleMamResponse(stanza);
        }
      }
    }
  }

  void _handleMamResponse(IqStanza stanza) {
    /*
<iq type='result' id='u29303'>
  <fin xmlns='urn:xmpp:mam:2' complete='true'>
    <set xmlns='http://jabber.org/protocol/rsm'>
      <first index='0'>23452-4534-1</first>
      <last>390-2342-22</last>
      <count>16</count>
    </set>
  </fin>
</iq>
     */
    var fin = stanza.getChild('fin');
    if (fin != null && fin.getNameSpace() == MAMNegotiator.XMLNS_MAM) {
      final isLastPage = fin.getAttribute('complete').value;
      final finSet = fin.getChild('set');
      if (finSet != null &&
          finSet.getNameSpace() == 'http://jabber.org/protocol/rsm') {
        final first = finSet.getChild('first')?.textValue;
        final last = finSet.getChild('last')?.textValue;
        // Отправляем в пагинацию ids первого и последнего полученного сообщений,
        // а также флаг для постраничной навигации
        _mamPaginatorController.add({
          'first': first,
          'last': last,
          'complete': isLastPage,
        });
      }
    }
  }

  void queryAll() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns(MAMNegotiator.XMLNS_MAM);
    query.setQueryId(AbstractStanza.getRandomId());
    iqStanza.addChild(query);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }

  void queryLastMessages({Jid jid, String before, String max = '20'}) {
    /*
<iq type='set' id='q29302'>
  <query xmlns='urn:xmpp:mam:0'>
    <x xmlns='jabber:x:data' type='submit'>
      <field var='FORM_TYPE' type='hidden'>
        <value>urn:xmpp:mam:0</value>
      </field>
      <field var='with'>
        <value>juliet@capulet.lit</value>
      </field>
    </x>
    <set xmlns='http://jabber.org/protocol/rsm'>
     <max>20</max>
     <before/>
    </set>
  </query>
</iq>
     */
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns(MAMNegotiator.XMLNS_MAM);
    iqStanza.addChild(query);
    var x = XElement.build();
    x.setType(FormType.SUBMIT);
    query.addChild(x);
    x.addField(FieldElement.build(
      varAttr: 'FORM_TYPE',
      typeAttr: 'hidden',
      value: MAMNegotiator.XMLNS_MAM,
    ));
    x.addField(FieldElement.build(
      varAttr: 'with',
      value: jid.userAtDomain,
    ));
    var setElment = SetElement();
    setElment.setXmlns('http://jabber.org/protocol/rsm');

    var maxElement = XmppElement();
    maxElement.name = 'max';
    maxElement.textValue = max;
    setElment.addChild(maxElement);

    var beforeElement = XmppElement();
    beforeElement.name = 'before';
    if (before != null) {
      beforeElement.textValue = before;
    }
    setElment.addChild(beforeElement);

    query.addChild(setElment);

    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }

  /* Запрашиваем сообщения после определенного сообщения с кодом */
  void queryAfterId({Jid jid, String afterId, String max = '20'}) {
    if (afterId == null) {
      queryLastMessages(jid: jid, max: max);
      return;
    }

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns(MAMNegotiator.XMLNS_MAM);
    iqStanza.addChild(query);
    var x = XElement.build();
    x.setType(FormType.SUBMIT);
    query.addChild(x);
    x.addField(FieldElement.build(
      varAttr: 'FORM_TYPE',
      typeAttr: 'hidden',
      value: MAMNegotiator.XMLNS_MAM,
    ));
    x.addField(FieldElement.build(
      varAttr: 'with',
      value: jid.userAtDomain,
    ));
    var setElment = SetElement();
    setElment.setXmlns('http://jabber.org/protocol/rsm');

    var maxElement = XmppElement();
    maxElement.name = 'max';
    maxElement.textValue = max;
    setElment.addChild(maxElement);

    // Обязательный (без значения 400 ответ)
    var afterElement = XmppElement();
    afterElement.name = 'after';
    afterElement.textValue = afterId;
    setElment.addChild(afterElement);

    query.addChild(setElment);

    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }


  void queryByTime({DateTime start, DateTime end, Jid jid}) {
    if (start == null && end == null && jid == null) {
      queryAll();
    } else {
      var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns(MAMNegotiator.XMLNS_MAM);
      query.setQueryId(AbstractStanza.getRandomId());
      iqStanza.addChild(query);
      var x = XElement.build();
      x.setType(FormType.SUBMIT);
      query.addChild(x);
      x.addField(FieldElement.build(
          varAttr: 'FORM_TYPE',
          typeAttr: 'hidden',
          value: MAMNegotiator.XMLNS_MAM));
      if (start != null) {
        x.addField(FieldElement.build(
            varAttr: 'start', value: start.toIso8601String()));
      }
      if (end != null) {
        x.addField(
            FieldElement.build(varAttr: 'end', value: end.toIso8601String()));
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
      _connection.writeStanza(iqStanza);
    }
  }

  void queryById({String beforeId, String afterId, Jid jid}) {
    /*
<iq type='set' id='q29303'>
  <query xmlns='urn:xmpp:mam:2'>
      <x xmlns='jabber:x:data' type='submit'>
        <field var='FORM_TYPE' type='hidden'><value>urn:xmpp:mam:2</value></field>
        <field var='start'><value>2010-08-07T00:00:00Z</value></field>
      </x>
      <set xmlns='http://jabber.org/protocol/rsm'>
         <max>10</max>
         <after>09af3-cc343-b409f</after>
      </set>
  </query>
</iq>
     */
    if (beforeId == null && afterId == null && jid == null) {
      queryAll();
    } else {
      var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
      var query = QueryElement();

      /*
      final xmlnsMam = (hasExtended != null && hasExtended)
          ? '${MAMNegotiator.XMLNS_MAM}#extended'
          : MAMNegotiator.XMLNS_MAM;
      OR
      isQueryByIdSupported
       */

      query.setXmlns(MAMNegotiator.XMLNS_MAM);
      query.setQueryId(AbstractStanza.getRandomId());
      iqStanza.addChild(query);
      var x = XElement.build();
      x.setType(FormType.SUBMIT);
      query.addChild(x);
      x.addField(FieldElement.build(
        varAttr: 'FORM_TYPE',
        typeAttr: 'hidden',
        value: MAMNegotiator.XMLNS_MAM,
      ));
      if (beforeId != null) {
        x.addField(FieldElement.build(varAttr: 'beforeId', value: beforeId));
      }
      if (afterId != null) {
        x.addField(FieldElement.build(varAttr: 'afterId', value: afterId));
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, null);
      _connection.writeStanza(iqStanza);
    }
  }
}

// method for getting module
extension MamModuleGetter on Connection {
  MessageArchiveManager getMamModule() {
    return MessageArchiveManager.getInstance(this);
  }
}
