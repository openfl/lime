package air.net;

extern class ServiceMonitor extends flash.events.EventDispatcher
{
	var available:Bool;
	var lastStatusUpdate(default, never):Date;
	var pollInterval:Float;
	var running(default, never):Bool;
	function new():Void;
	function start():Void;
	function stop():Void;
	private function checkStatus():Void;
	static function makeJavascriptSubclass(constructorFunction:Dynamic):Void;
}
