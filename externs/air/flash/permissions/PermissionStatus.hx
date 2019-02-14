package flash.permissions;

extern class PermissionStatus
{
	function new():Void;
	static var DENIED(default, never):String;
	static var GRANTED(default, never):String;
	static var UNKNOWN(default, never):String;
}
