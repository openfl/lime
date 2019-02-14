package flash.html.script;

extern class PropertyEnumHelper
{
	function new(enumPropertiesClosure:Dynamic, getPropertyClosure:Dynamic):Void;
	function nextName(index:Int):String;
	function nextNameIndex(lastIndex:Int):Int;
	function nextValue(index:Int):Dynamic;
}
