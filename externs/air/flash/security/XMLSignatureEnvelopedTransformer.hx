package flash.security;

extern class XMLSignatureEnvelopedTransformer
{
	function new():Void;
	function transform(sig:flash.xml.XML, doc:flash.xml.XML):flash.xml.XML;
}
