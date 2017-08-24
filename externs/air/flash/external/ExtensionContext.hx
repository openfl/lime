package flash.external;

extern class ExtensionContext extends flash.events.EventDispatcher {
	var actionScriptData : Dynamic;
	function new() : Void;
	function call(functionName : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic ) : Dynamic;
	function dispose() : Void;
	static function createExtensionContext(extensionID : String, contextType : String) : ExtensionContext;
	static function getExtensionDirectory(extensionID : String) : flash.filesystem.File;
}
