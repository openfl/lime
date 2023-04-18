package flash.desktop;

extern class NativeApplication extends flash.events.EventDispatcher
{
	var activeWindow(default, never):flash.display.NativeWindow;
	var applicationDescriptor(default, never):flash.xml.XML;
	var applicationID(default, never):String;
	var autoExit:Bool;
	var executeInBackground:Bool;
	var icon(default, never):InteractiveIcon;
	var idleThreshold:Int;
	var isCompiledAOT(default, never):Bool;
	var menu:flash.display.NativeMenu;
	var openedWindows(default, never):Array<Dynamic>;
	var publisherID(default, never):String;
	var runtimePatchLevel(default, never):UInt;
	var runtimeVersion(default, never):String;
	var startAtLogin:Bool;
	var systemIdleMode:SystemIdleMode;
	var timeSinceLastUserInput(default, never):Int;
	function new():Void;
	function activate(?window:flash.display.NativeWindow):Void;
	function clear():Bool;
	function copy():Bool;
	function cut():Bool;
	function exit(?errorCode:Int):Void;
	function getDefaultApplication(extension:String):String;
	function isSetAsDefaultApplication(extension:String):Bool;
	function paste():Bool;
	function removeAsDefaultApplication(extension:String):Void;
	function selectAll():Bool;
	function setAsDefaultApplication(extension:String):Void;
	static var nativeApplication(default, never):NativeApplication;
	static var supportsDefaultApplication(default, never):Bool;
	static var supportsDockIcon(default, never):Bool;
	static var supportsMenu(default, never):Bool;
	static var supportsStartAtLogin(default, never):Bool;
	static var supportsSystemTrayIcon(default, never):Bool;
}
