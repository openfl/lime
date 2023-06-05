package flash.display;

@:require(flash10_1) extern class NativeMenu extends flash.events.EventDispatcher
{
	#if (haxe_ver < 4.3)
	#if air
	var items:Array<NativeMenuItem>;
	var numItems(default, never):Int;
	var parent(default, never):NativeMenu;
	static var isSupported(default, never):Bool;
	#end
	#else
	#if air
	@:flash.property var items(get, set):Array<NativeMenuItem>;
	@:flash.property var numItems(get, never):Int;
	@:flash.property var parent(get, never):NativeMenu;
	@:flash.property static var isSupported(get, never):Bool;
	#end
	#end
	function new():Void;
	#if air
	function addItem(item:NativeMenuItem):NativeMenuItem;
	function addItemAt(item:NativeMenuItem, index:Int):NativeMenuItem;
	function addSubmenu(submenu:NativeMenu, label:String):NativeMenuItem;
	function addSubmenuAt(submenu:NativeMenu, index:Int, label:String):NativeMenuItem;
	function clone():NativeMenu;
	function containsItem(item:NativeMenuItem):Bool;
	function dispatchContextMenuSelect(event:flash.events.MouseEvent):Dynamic;
	function display(stage:Stage, stageX:Float, stageY:Float):Void;
	function getItemAt(index:Int):NativeMenuItem;
	function getItemByName(name:String):NativeMenuItem;
	function getItemIndex(item:NativeMenuItem):Int;
	function removeAllItems():Void;
	function removeItem(item:NativeMenuItem):NativeMenuItem;
	function removeItemAt(index:Int):NativeMenuItem;
	function setItemIndex(item:NativeMenuItem, index:Int):Void;
	#end

	#if (haxe_ver >= 4.3)
	#if air
	private function get_items():Array<NativeMenuItem>;
	private function get_numItems():Int;
	private function get_parent():NativeMenu;
	private function set_items(value:Array<NativeMenuItem>):Array<NativeMenuItem>;
	private static function get_isSupported():Bool;
	#end
	#end
}
