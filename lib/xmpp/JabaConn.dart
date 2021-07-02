import 'dart:async';
import 'dart:io';
import 'package:xml/xml.dart' as xml;

import 'package:masterme_chat/xmpp/Jaba.dart';
import 'package:masterme_chat/xmpp/StanzaBuilder.dart';

class JabaConn {
  String url;
  String domain;
  WebSocket socket;

  // Subscribtion on socket
  StreamSubscription _socketListen;
  StreamSubscription get socketListen {
    return _socketListen;
  }
  set socketListen(StreamSubscription listen) {
    if (listen != null) _socketListen = listen;
  }

  JabaConn({String url}){
    this.url = url;
    this.domain = url.replaceAll('wss://', '').split('/')[0];
  }

  void connect() {
    // Ensure that there is no open WebSocket from a previous Connection.
    //this._disconnect();

    if (this.socketListen == null || this.socket == null) {
      // Create the new WebSocket
      WebSocket.connect(this.url, protocols: ['xmpp']).then((WebSocket socket) {
        this.socket = socket;
        this.socketListen = this.socket.listen(
            this._connectCbWrapper,
            onError: this._onError,
            //onDone: this._onClose,
        );
        this._onOpen();
      }).catchError((e) {
        print(e);
        //this._conn.connexionError("impossible de joindre le serveur XMPP : $e");
      });
    }
  }

  /* PrivateFunction: _onOpen
   * _Private_ function to handle websockets connection setup.
   *
   * The opening stream tag is sent here.
   */
  _onOpen() {
    //Strophe.info("Websocket open");
    StanzaBuilder start = this._buildStream();
    //this._conn.xmlOutput(start.tree());

    String startString = start.tree().toXmlString();
    //this._conn.rawOutput(startString);
    print("+_+" + " " + startString + " " + socket.toString());
    if (this.socket != null) this.socket.add(startString);
  }

  StanzaBuilder _buildStream() {
    return Jaba.$build("open", {
      "xmlns": Jaba.NS['FRAMING'],
      "to": this.domain,
      "version": '1.0'
    });
  }


  /* PrivateFunction: _connect_cb_wrapper
   * _Private_ function that handles the first connection messages.
   *
   * On receiving an opening stream tag this callback replaces itself with the real
   * message handler. On receiving a stream error the connection is terminated.
   */
  void _connectCbWrapper(message) {
    try {
      message = message as String;
    } catch (e) {
      message = message.toString();
    }
    print('--------' + message);
    if (message == null || message.isEmpty) return;
    if (message.trim().indexOf('<open ') == 0 ||
        message.trim().indexOf('<?xml') == 0) {
      // Strip the XML Declaration, if there is one
      String data = message.replaceAll(new RegExp(r'^(<\?.*?\?>\s*)*'), '');
      if (data == '') return;

      xml.XmlDocument streamStart = xml.XmlDocument.parse(data);
      //this._conn.xmlInput(streamStart.rootElement);
      //this._conn.rawInput(message);

      //_handleStreamSteart will check for XML errors and disconnect on error
      if (this._handleStreamStart(streamStart)) {
        //_connect_cb will check for stream:error and disconnect on error
        //this.connectCb(streamStart.rootElement);
      }
    } else if (message.trim().indexOf("<close ") == 0) {
      // <close xmlns="urn:ietf:params:xml:ns:xmpp-framing />
      //this._conn.rawInput(message);
      //this._conn.xmlInput(xml.parse(message).rootElement);
      String seeUri =
      xml.XmlDocument.parse(message).rootElement.getAttribute("see-other-uri");
      if (seeUri != null && seeUri.isNotEmpty) {
        //this._conn.changeConnectStatus(Jaba.Status['REDIRECT'], "Received see-other-uri, resetting connection");
        //this._conn.reset();
        //this._conn.service = seeUri;
        this.connect();
      } else {
        //this._conn.changeConnectStatus(Strophe.Status['CONNFAIL'], "Received closing stream");
        //this._conn.doDisconnect();
      }
    } else {
      String string = this._streamWrap(message);
      xml.XmlDocument elem = xml.XmlDocument.parse(string);
      this.socketListen.onData(this._onMessage);
      //this.connectCb(elem, null, message);
    }
  }


  /* PrivateFunction: _onMessage
   * _Private_ function to handle websockets messages.
   *
   * This function parses each of the messages as if they are full documents.
   * [TODO : We may actually want to use a SAX Push parser].
   *
   * Since all XMPP traffic starts with
   *  <stream:stream version='1.0'
   *                 xml:lang='en'
   *                 xmlns='jabber:client'
   *                 xmlns:stream='http://etherx.jabber.org/streams'
   *                 id='3697395463'
   *                 from='SERVER'>
   *
   * The first stanza will always fail to be parsed.
   *
   * Additionally, the seconds stanza will always be <stream:features> with
   * the stream NS defined in the previous stanza, so we need to 'force'
   * the inclusion of the NS in this stanza.
   *
   * Parameters:
   * (string) message - The websocket message.
   */
  void _onMessage(dynamic message) {
    message = message as String;
    xml.XmlDocument elem;
    String data;
    // check for closing stream
    String close = '<close xmlns="urn:ietf:params:xml:ns:xmpp-framing" />';
    if (message == close) {
      //this._conn.rawInput(close);
      //this._conn.xmlInput(xml.parse(message).rootElement);
      //if (!this._conn.disconnecting) {
      //  this._conn.doDisconnect();
      //}
      return;
    } else if (message.trim().indexOf("<open ") == 0) {
      // This handles stream restarts
      elem = xml.XmlDocument.parse(message);
      if (!this._handleStreamStart(elem)) {
        return;
      }
    } else {
      data = this._streamWrap(message);
      elem = xml.XmlDocument.parse(data);
    }

    //if (this._checkStreamError(elem, Jaba.Status['ERROR'])) {
    //  return;
    //}

    //handle unavailable presence stanza before disconnecting
    xml.XmlElement firstChild = elem.firstChild;
    //if (this.disconnecting &&
    //    firstChild.name.qualified == "presence" &&
    //    firstChild.getAttribute("type") == "unavailable") {
      //this._conn.xmlInput(elem.root);
      //this._conn.rawInput(Strophe.serialize(elem));
      // if we are already disconnecting we will ignore the unavailable stanza and
      // wait for the </stream:stream> tag before we close the connection
    //  return;
    //}
    this.dataRecv(elem.rootElement, message);
  }


  /* PrivateFunction: _dataRecv
   *  _Private_ handler to processes incoming data from the the connection.
   *
   *  Except for _connect_cb handling the initial connection request,
   *  this function handles the incoming data for all requests.  This
   *  function also fires stanza handlers this match each incoming
   *  stanza.
   *
   *  Parameters:
   *    (Strophe.Request) req - The request this has data ready.
   *    (string) req - The stanza a raw string (optiona).
   */

  dataRecv(req, [String raw]) {
    //Strophe.info("_dataRecv called");


    print("DATA! " + raw);
    /*



    xml.XmlElement elem = this.reqToData(req);
    if (elem == null) {
      return;
    }

    if (elem.name.qualified == this._proto.strip && elem.children.length > 0) {
      this.xmlInput(elem.firstChild);
    } else {
      this.xmlInput(elem);
    }

    if (raw != null) {
      this.rawInput(raw);
    } else {
      this.rawInput(Strophe.serialize(elem));
    }

    // remove handlers scheduled for deletion
    int i;
    StanzaHandler hand;
    while (this.removeHandlers.length > 0) {
      hand = this.removeHandlers.removeLast();
      i = this.handlers.indexOf(hand);
      if (i >= 0) {
        this.handlers.removeAt(i);
      }
    }
    // add handlers scheduled for addition
    while (this.addHandlers.length > 0) {
      this.handlers.add(this.addHandlers.removeLast());
    }
    // handle graceful disconnect
    if (this.disconnecting && this._proto.emptyQueue()) {
      this._doDisconnect();
      return;
    }
    xml.XmlElement stanza;
    if (elem.name.qualified == this._proto.strip)
      stanza = elem.firstChild as xml.XmlElement;
    else
      stanza = elem;
    String type = stanza.getAttribute('type');
    if (type == null) {
      try {
        type = (elem.firstChild as xml.XmlElement).getAttribute('type');
      } catch (e) {}
    }
    String cond;
    Iterable<xml.XmlElement> conflict;
    if (type != null && type == "terminate") {
      // Don't process stanzas this come in after disconnect
      if (this.disconnecting) {
        return;
      }

      // an error occurred

      cond = elem.getAttribute('condition');
      conflict = elem.document.findAllElements("conflict");
      if (cond != null) {
        if (cond == "remote-stream-error" && conflict.length > 0) {
          cond = "conflict";
        }
        this._changeConnectStatus(Strophe.Status['CONNFAIL'], cond);
      } else {
        this._changeConnectStatus(Strophe.Status['CONNFAIL'],
            Strophe.ErrorCondition['UNKOWN_REASON']);
      }
      this._doDisconnect(cond);
      return;
    }
    // send each incoming stanza through the handler chain
    Strophe.forEachChild(elem, null, (child) {
      // process handlers
      List<StanzaHandler> newList = this.handlers;
      this.handlers = [];

      for (int i = 0; i < newList.length; i++) {
        StanzaHandler hand = newList.elementAt(i);
        // encapsulate 'handler.run' not to lose the whole handler list if
        // one of the handlers throws an exception
        try {
          if (hand.isMatch(child) && (this.authenticated || !hand.user)) {
            if (hand.run(child)) {
              this.handlers.add(hand);
            }
          } else {
            this.handlers.add(hand);
          }
        } catch (e) {
          // if the handler throws an exception, we consider it as false
          Strophe.warn('Removing Strophe handlers due to uncaught exception: ' +
              e.toString());
        }
      }
    });

     */
  }

  /* PrivateFunction: _handleStreamStart
   * _Private_ function that checks the opening <open /> tag for errors.
   * Disconnects if there is an error and returns false, true otherwise.
   *  Parameters:
   *    (Node) message - Stanza containing the <open /> tag.
   */
  bool _handleStreamStart(xml.XmlDocument message) {
    String error = "";

    // Check for errors in the <open /> tag
    String ns = message.rootElement.getAttribute("xmlns");
    if (ns == null) {
      error = "Missing xmlns in <open />";
    } else if (ns != Jaba.NS['FRAMING']) {
      error = "Wrong xmlns in <open />: " + ns;
    }

    String ver = message.rootElement.getAttribute("version");
    if (ver == null) {
      error = "Missing version in <open />";
    } else if (ver != "1.0") {
      error = "Wrong version in <open />: " + ver;
    }

    if (error != null && error.isNotEmpty) {
      //this.changeConnectStatus(Jaba.Status['CONNFAIL'], error);
      //this.doDisconnect();
      return false;
    }

    return true;
  }


  /* PrivateFunction: _onError
   * _Private_ function to handle websockets errors.
   *
   * Parameters:
   * (Object) error - The websocket error.
   */
  void _onError(Object error) {
    print('Websocket error ' + error.toString());
    //Jaba.error("Websocket error " + error.toString());
    //this._conn.changeConnectStatus(Strophe.Status['CONNFAIL'], "The WebSocket connection could not be established or was disconnected.");
    //this._disconnect();
  }

  /* PrivateFunction _streamWrap
   *  _Private_ helper function to wrap a stanza in a <stream> tag.
   *  This is used so Strophe can process stanzas from WebSockets like BOSH
   */
  String _streamWrap(String stanza) {
    return "<wrapper>" + stanza + '</wrapper>';
  }

}