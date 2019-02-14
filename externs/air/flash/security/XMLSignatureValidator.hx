package flash.security;

extern class XMLSignatureValidator extends flash.events.EventDispatcher
{
	var digestStatus(default, never):String;
	var identityStatus(default, never):String;
	var referencesStatus(default, never):String;
	var referencesValidationSetting:ReferencesValidationSetting;
	var revocationCheckSetting:RevocationCheckSettings;
	var signerCN(default, never):String;
	var signerDN(default, never):String;
	var signerExtendedKeyUsages(default, never):Array<Dynamic>;
	var signerTrustSettings(default, never):Array<Dynamic>;
	var uriDereferencer:IURIDereferencer;
	var useSystemTrustStore:Bool;
	var validityStatus(default, never):String;
	function new():Void;
	function addCertificate(cert:flash.utils.ByteArray, trusted:Bool):Dynamic;
	function verify(signature:flash.xml.XML):Void;
	static var isSupported(default, never):Bool;
}
