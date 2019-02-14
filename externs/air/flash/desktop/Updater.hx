package flash.desktop;

extern class Updater
{
	function new():Void;
	function update(airFile:flash.filesystem.File, version:String):Void;
	static var isSupported(default, never):Bool;
}
