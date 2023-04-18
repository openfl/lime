package flash.ui;

@:final extern class ContextMenuItem #if air extends flash.display.NativeMenuItem #end
{
	var caption:String;
	var separatorBefore:Bool;
	var visible:Bool;
	function new(caption:String, separatorBefore:Bool = false, enabled:Bool = true, visible:Bool = true):Void;
	#if !air
	function clone():ContextMenuItem;
	#end
}
