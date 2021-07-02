import 'package:xml/xml.dart' as xml;

import 'package:masterme_chat/xmpp/StanzaBuilder.dart';
import 'package:masterme_chat/xmpp/XMLUtils.dart';
import 'package:masterme_chat/xmpp/JabaConn.dart';

/*
XMPP implemetation
*/

class Jaba {
  XMLUtils xmlUtils = XMLUtils();

  /* Common namespace constants from the XMPP RFCs and XEPs. */
  static const NS = {
    'HTTPBIND'    : "http://jabber.org/protocol/httpbind",    // HTTP BIND namespace from XEP 124.
    'BOSH'        : "urn:xmpp:xbosh",                         // BOSH namespace from XEP 206.
    'CLIENT'      : "jabber:client",                          // Main XMPP client namespace.
    'AUTH'        : "jabber:iq:auth",                         // Legacy authentication namespace.
    'ROSTER'      : "jabber:iq:roster",                       // Roster operations namespace.
    'PROFILE'     : "jabber:iq:profile",                      // Profile namespace.
    'DISCO_INFO'  : "http://jabber.org/protocol/disco#info",  // Service discovery info namespace from XEP 30.
    'DISCO_ITEMS' : "http://jabber.org/protocol/disco#items", // Service discovery items namespace from XEP 30.
    'MUC'         : "http://jabber.org/protocol/muc",         // Multi-User Chat namespace from XEP 45.
    'SASL'        : "urn:ietf:params:xml:ns:xmpp-sasl",       // XMPP SASL namespace from RFC 3920.
    'STREAM'      : "http://etherx.jabber.org/streams",       // XMPP Streams namespace from RFC 3920.
    'FRAMING'     : "urn:ietf:params:xml:ns:xmpp-framing",
    'BIND'        : "urn:ietf:params:xml:ns:xmpp-bind",       // XMPP Binding namespace from RFC 3920.
    'SESSION'     : "urn:ietf:params:xml:ns:xmpp-session",    // XMPP Session namespace from RFC 3920.
    'VERSION'     : "jabber:iq:version",
    'STANZAS'     : "urn:ietf:params:xml:ns:xmpp-stanzas",
    'XHTML_IM'    : "http://jabber.org/protocol/xhtml-im",    // XHTML-IM namespace from XEP 71.
    'XHTML'       : "http://www.w3.org/1999/xhtml",           // XHTML body namespace from XEP 71.
  };

  // Connections status constants
  static const Status = {
    'ERROR'          : 0, // An error has occurred
    'CONNECTING'     : 1, // The connection is currently being made
    'CONNFAIL'       : 2, // The connection attempt failed
    'AUTHENTICATING' : 3, // The connection is authenticating
    'AUTHFAIL'       : 4, // The authentication attempt failed
    'CONNECTED'      : 5, // The connection has succeeded
    'DISCONNECTED'   : 6, // The connection has been terminated
    'DISCONNECTING'  : 7, // The connection is currently being terminated
    'ATTACHED'       : 8, // The connection has been attached
    'REDIRECT'       : 9,
  };

  static Map<String, dynamic> XHTML = {
    "tags": [
      'a',
      'blockquote',
      'br',
      'cite',
      'em',
      'img',
      'li',
      'ol',
      'p',
      'span',
      'strong',
      'ul',
      'body'
    ],
    'attributes': {
      'a': ['href'],
      'blockquote': ['style'],
      'br': [],
      'cite': ['style'],
      'em': [],
      'img': ['src', 'alt', 'style', 'height', 'width'],
      'li': ['style'],
      'ol': ['style'],
      'p': ['style'],
      'span': ['style'],
      'strong': [],
      'ul': ['style'],
      'body': []
    },
    'css': [
      'background-color',
      'color',
      'font-family',
      'font-size',
      'font-style',
      'font-weight',
      'margin-left',
      'margin-right',
      'text-align',
      'text-decoration'
    ],
    /** Function: XHTML.validTag
     *
     * Utility method to determine whether a tag is allowed
     * in the XHTML_IM namespace.
     *
     * XHTML tag names are case sensitive and must be lower case.
     */
    'validTag': (String tag) {
      for (int i = 0; i < Jaba.XHTML['tags'].length; i++) {
        if (tag == Jaba.XHTML['tags'][i]) {
          return true;
        }
      }
      return false;
    },
    /** Function: XHTML.validAttribute
     *
     * Utility method to determine whether an attribute is allowed
     * as recommended per XEP-0071
     *
     * XHTML attribute names are case sensitive and must be lower case.
     */
    'validAttribute': (String tag, String attribute) {
      if (Jaba.XHTML['attributes'][tag] != null &&
          Jaba.XHTML['attributes'][tag].length > 0) {
        for (int i = 0; i < Jaba.XHTML['attributes'][tag].length; i++) {
          if (attribute == Jaba.XHTML['attributes'][tag][i]) {
            return true;
          }
        }
      }
      return false;
    },
    'validCSS': (style) {
      for (int i = 0; i < Jaba.XHTML['css'].length; i++) {
        if (style == Jaba.XHTML['css'][i]) {
          return true;
        }
      }
      return false;
    }
  };

  // Connection to server
  JabaConn conn;

  String login;
  String passwd;
  String url;

  Jaba({login, passwd}){
    this.login = login;
    this.passwd = passwd;

    this.url = 'wss://' + login.toString().split('@')[1] + '/wss/';
    this.conn = JabaConn(url: this.url);
  }

  static StanzaBuilder $build(String name, Map<String, dynamic> attrs) {
    return StanzaBuilder(name, attrs);
  }

}


void main() async {
  Jaba jabber = Jaba(
    login: 'jocker@anhel.1sprav.ru',
    passwd: '',
  );
  jabber.conn.connect();
  //print(jabber.xmlUtils.xmlElement('div'));
}