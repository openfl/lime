package flash.data;

extern class SQLConnection extends flash.events.EventDispatcher
{
	var autoCompact(default, never):Bool;
	var cacheSize:UInt; // default 2000
	var columnNameStyle:SQLColumnNameStyle;
	var connected(default, never):Bool;
	var inTransaction(default, never):Bool;
	var lastInsertRowID(default, never):Float;
	var pageSize(default, never):UInt;
	var totalChanges(default, never):Float;
	function new():Void;
	function analyze(?resourceName:String, ?responder:flash.net.Responder):Void;
	function attach(name:String, ?reference:Dynamic, ?responder:flash.net.Responder, ?encryptionKey:flash.utils.ByteArray):Void;
	function begin(?option:String, ?responder:flash.net.Responder):Void;
	function cancel(?responder:flash.net.Responder):Void;
	function close(?responder:flash.net.Responder):Void;
	function commit(?responder:flash.net.Responder):Void;
	function compact(?responder:flash.net.Responder):Void;
	function deanalyze(?responder:flash.net.Responder):Void;
	function detach(name:String, ?responder:flash.net.Responder):Void;
	function getSchemaResult():SQLSchemaResult;
	function loadSchema(?type:Class<Dynamic>, ?name:String, ?database:String = "main", ?includeColumnSchema:Bool = true, ?responder:flash.net.Responder):Void;
	function open(?reference:Dynamic, ?openMode:SQLMode = SQLMode.CREATE, ?autoCompact:Bool = false, ?pageSize:Int = 1024,
		?encryptionKey:flash.utils.ByteArray):Void;
	function openAsync(?reference:Dynamic, ?openMode:SQLMode = SQLMode.CREATE, ?responder:flash.net.Responder, ?autoCompact:Bool = false,
		?pageSize:Int = 1024, ?encryptionKey:flash.utils.ByteArray):Void;
	function reencrypt(newEncryptionKey:flash.utils.ByteArray, ?responder:flash.net.Responder):Void;
	function releaseSavepoint(?name:String, ?responder:flash.net.Responder):Void;
	function rollback(?responder:flash.net.Responder):Void;
	function rollbackToSavepoint(?name:String, ?responder:flash.net.Responder):Void;
	function setSavepoint(?name:String, ?responder:flash.net.Responder):Void;
	static var isSupported(default, never):Bool;
}
