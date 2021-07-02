import 'package:xml/xml.dart' as xml;

import 'package:masterme_chat/xmpp/Jaba.dart';

/*
XML features class
*/
class XMLUtils {
  final xml.XmlBuilder xmlBuilder = new xml.XmlBuilder();

  /* Function: xmlElement
   *  Create an XML DOM element.
   *
   *  This function creates an XML DOM element correctly across all
   *  implementations. Note that these are not HTML DOM elements, which
   *  aren't appropriate for XMPP stanzas.
   *
   *  Parameters:
   *    (String) name - The name for the element.
   *    (Array|Object) attrs - An optional array or object containing
   *      key/value pairs to use as element attributes. The object should
   *      be in the format {'key': 'value'} or {key: 'value'}. The array
   *      should have the format [['key1', 'value1'], ['key2', 'value2']].
   *    (String) text - The text child data for the element.
   *
   *  Returns:
   *    A new XML DOM element.
   */
  xml.XmlNode xmlElement(String name, {dynamic attrs, String text}) {
    if (name == null || name.isEmpty || name.trim().length == 0) {
      return null;
    }
    if (attrs != null &&
        (attrs is! List<List<String>>) &&
        (attrs is! Map<String, dynamic>)) {
      return null;
    }
    Map<String, String> attributes = {};
    if (attrs != null) {
      if (attrs is List<List<String>>) {
        for (int i = 0; i < attrs.length; i++) {
          List<String> attr = attrs[i];
          if (attr.length == 2 && attr[1] != null && attr.isNotEmpty) {
            attributes[attr[0]] = attr[1].toString();
          }
        }
      } else if (attrs is Map<String, dynamic>) {
        List<String> keys = attrs.keys.toList();
        for (int i = 0, len = keys.length; i < len; i++) {
          String key = keys[i];
          if (key != null && key.isNotEmpty && attrs[key] != null) {
            attributes[key] = attrs[key].toString();
          }
        }
      }
    }
    xmlBuilder.element(name, attributes: attributes, nest: text);
    return xmlBuilder.buildDocument();
  }


  /* Function: copyElement
   *  Copy an XML DOM element.
   *  This function copies a DOM element and all its descendants and returns
   *  the new copy.
   *
   *  Parameters:
   *    (XMLElement) elem - A DOM element.
   *  Returns:
   *    A new, copied DOM element tree.
   */
  xml.XmlNode copyElement(xml.XmlNode elem) {
    var el = elem;
    if (elem.nodeType == xml.XmlNodeType.ELEMENT) {
      el = elem.copy();
    } else if (elem.nodeType == xml.XmlNodeType.TEXT) {
      el = elem;
    } else if (elem.nodeType == xml.XmlNodeType.DOCUMENT) {
      el = elem.document.rootElement;
    }
    return el;
  }


  /* Function: xmlTextNode
   *  Creates an XML DOM text node.
   *
   *  Parameters:
   *    (String) text - The content of the text node.
   *
   *  Returns:
   *    A new XML DOM text node.
   */
  xml.XmlNode xmlTextNode(String text) {
    xmlBuilder.element('strophe', nest: text);
    return xmlBuilder.buildDocument();
  }


  /* Function: createHtml
   *  Copy an HTML DOM element into an XML DOM.
   *  This function copies a DOM element and all its descendants and returns
   *  the new copy.
   *
   *  Parameters:
   *    (HTMLElement) elem - A DOM element.
   *
   *  Returns:
   *    A new, copied DOM element tree.
   */
  xml.XmlNode createHtml(xml.XmlNode elem) {
    xml.XmlNode el;
    String tag;
    if (elem.nodeType == xml.XmlNodeType.ELEMENT) {
      // XHTML tags must be lower case.
      //tag = elem.
      if (Jaba.XHTML['validTag'](tag)) {
        try {
          el = copyElement(elem);
        } catch (e) {
          // invalid elements
          el = xmlTextNode('');
        }
      } else {
        el = copyElement(elem);
      }
    } else if (elem.nodeType == xml.XmlNodeType.DOCUMENT_FRAGMENT) {
      el = copyElement(elem);
    } else if (elem.nodeType == xml.XmlNodeType.TEXT) {
      el = xmlTextNode(elem.toString());
    }
    return el;
  }

}