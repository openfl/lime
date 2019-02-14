package flash.external;

@:final extern class ExtensionContext extends flash.events.EventDispatcher
{
	var actionScriptData:flash.utils.Object;
	function new():Void;
	// function _disposed() : Bool;
	function call(functionName:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):Dynamic;
	function dispose():Void;
	// function getActionScriptData() : flash.utils.Object;
	// function setActionScriptData(p1 : flash.utils.Object) : Void;
	static function createExtensionContext(extensionID:String, contextType:String):ExtensionContext;
	static function getExtensionDirectory(extensionID:String):flash.filesystem.File;
}
