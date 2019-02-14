package flash.security;

extern class XMLCanonicalizer
{
	function new():Void;
	function CanonicalizeXML(xml:flash.xml.XML):String;
	function CanonicalizeXMLList(xmlList:flash.xml.XMLList):String;
}
