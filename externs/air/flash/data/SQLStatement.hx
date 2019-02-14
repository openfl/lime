package flash.data;

extern class SQLStatement extends flash.events.EventDispatcher
{
	var executing(default, never):Bool;
	var itemClass:Class<Dynamic>;
	var parameters(default, never):Dynamic;
	var sqlConnection:SQLConnection;
	var text:String;
	function new():Void;
	function cancel():Void;
	function clearParameters():Void;
	function execute(?prefetch:Int = -1, ?responder:flash.net.Responder):Void;
	function getResult():SQLResult;
	function next(?prefetch:Int = -1, ?responder:flash.net.Responder):Void;
}
