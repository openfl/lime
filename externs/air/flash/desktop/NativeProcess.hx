package flash.desktop;

extern class NativeProcess extends flash.events.EventDispatcher
{
	var running(default, never):Bool;
	var standardError(default, never):flash.utils.IDataInput;
	var standardInput(default, never):flash.utils.IDataOutput;
	var standardOutput(default, never):flash.utils.IDataInput;
	function new():Void;
	function closeInput():Void;
	function exit(force:Bool = false):Void;
	function start(info:NativeProcessStartupInfo):Void;
	static var isSupported(default, never):Bool;
	static function isValidExecutable(f:flash.filesystem.File):Bool;
}
