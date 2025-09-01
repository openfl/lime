package flash.display;

@:require(flash10_1) extern class NativeMenuItem extends flash.events.EventDispatcher
{
	#if (haxe_ver < 4.3)
	var checked:Bool;
	var data:Dynamic;
	var enabled:Bool;
	var isSeparator(default, never):Bool;
	var keyEquivalent:String;
	var keyEquivalentModifiers:Array<UInt>;
	var label:String;
	var menu(default, never):NativeMenu;
	var mnemonicIndex:Int;
	var name:String;
	var submenu:NativeMenu;
	#else
	@:flash.property var checked(get, set):Bool;
	@:flash.property var data(get, set):Dynamic;
	@:flash.property var enabled(get, set):Bool;
	@:flash.property var isSeparator(get, never):Bool;
	@:flash.property var keyEquivalent(get, set):String;
	@:flash.property var keyEquivalentModifiers(get, set):Array<UInt>;
	@:flash.property var label(get, set):String;
	@:flash.property var menu(get, never):NativeMenu;
	@:flash.property var mnemonicIndex(get, set):Int;
	@:flash.property var name(get, set):String;
	@:flash.property var submenu(get, set):NativeMenu;
	#end

	function new(?label:String = "", ?isSeparator:Bool = false):Void;
	function clone():NativeMenuItem;
	override function toString():String;

	#if (haxe_ver >= 4.3)
	private function get_checked():Bool;
	private function get_data():Dynamic;
	private function get_enabled():Bool;
	private function get_isSeparator():Bool;
	private function get_keyEquivalent():String;
	private function get_keyEquivalentModifiers():Array<UInt>;
	private function get_label():String;
	private function get_menu():NativeMenu;
	private function get_mnemonicIndex():Int;
	private function get_name():String;
	private function get_submenu():NativeMenu;
	private function set_checked(value:Bool):Bool;
	private function set_data(value:Dynamic):Dynamic;
	private function set_enabled(value:Bool):Bool;
	private function set_keyEquivalent(value:String):String;
	private function set_keyEquivalentModifiers(value:Array<UInt>):Array<UInt>;
	private function set_label(value:String):String;
	private function set_mnemonicIndex(value:Int):Int;
	private function set_name(value:String):String;
	private function set_submenu(value:NativeMenu):NativeMenu;
	#end
}
