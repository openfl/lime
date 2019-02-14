package flash.display;

@:require(flash10_1) extern class NativeMenu extends flash.events.EventDispatcher
{
	#if air
	var items:Array<NativeMenuItem>;
	var numItems(default, never):Int;
	var parent(default, never):NativeMenu;
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
	static var isSupported(default, never):Bool;
	#end
}
