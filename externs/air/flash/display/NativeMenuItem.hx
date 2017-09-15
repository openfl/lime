package flash.display;

@:require(flash10_1) extern class NativeMenuItem extends flash.events.EventDispatcher {
	#if air
	var checked : Bool;
	var data : Dynamic;
	#end
	var enabled : Bool;
	#if air
	var isSeparator(default,never) : Bool;
	var keyEquivalent : flash.ui.Keyboard;
	var keyEquivalentModifiers : Array<flash.ui.Keyboard>;
	var label : String;
	var menu(default,never) : NativeMenu;
	var mnemonicIndex : Int;
	var name : String;
	var submenu : NativeMenu;
	#end
	function new(#if air ?label : String="", ?isSeparator : Bool=false #end) : Void;
	#if air
	function clone() : NativeMenuItem;
	override function toString() : String;
	#end
}
