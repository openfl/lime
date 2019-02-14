package flash.data;

extern class EncryptedLocalStore
{
	static var isSupported(default, never):Bool;
	static function getItem(name:String):flash.utils.ByteArray;
	static function removeItem(name:String):Void;
	static function reset():Void;
	static function setItem(name:String, data:flash.utils.ByteArray, stronglyBound:Bool = false):Void;
}
