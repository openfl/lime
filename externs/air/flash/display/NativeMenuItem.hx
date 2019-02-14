package flash.display;

@:require(flash10_1) extern class NativeMenuItem extends flash.events.EventDispatcher
{
	var checked:Bool;
	var data:Dynamic;
	var enabled:Bool;
	var isSeparator(default, never):Bool;
	var keyEquivalent:flash.ui.Keyboard;
	var keyEquivalentModifiers:Array<flash.ui.Keyboard>;
	var label:String;
	var menu(default, never):NativeMenu;
	var mnemonicIndex:Int;
	var name:String;
	var submenu:NativeMenu;
	function new(?label:String = "", ?isSeparator:Bool = false):Void;
	function clone():NativeMenuItem;
	override function toString():String;
}
