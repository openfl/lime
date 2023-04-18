package air.update;

extern class ApplicationUpdaterUI extends flash.events.EventDispatcher
{
	var configurationFile:flash.filesystem.File;
	var currentVersion(default, never):String;
	var delay:Float;
	var isCheckForUpdateVisible:Bool;
	var isDownloadProgressVisible:Bool;
	var isDownloadUpdateVisible:Bool;
	var isFileUpdateVisible:Bool;
	var isFirstRun(default, never):Bool;
	var isInstallUpdateVisible:Bool;
	var isNewerVersionFunction:Dynamic;
	var isUnexpectedErrorVisible:Bool;
	var isUpdateInProgress(default, never):Bool;
	var localeChain:Array<Dynamic>;
	var previousApplicationStorageDirectory(default, never):flash.filesystem.File;
	var previousVersion(default, never):String;
	var updateDescriptor(default, never):flash.xml.XML;
	var updateURL:String;
	var wasPendingUpdate(default, never):Bool;
	function new():Void;
	function addResources(lang:String, res:Dynamic):Void;
	function cancelUpdate():Void;
	function checkNow():Void;
	function initialize():Void;
	function installFromAIRFile(file:flash.filesystem.File):Void;
	private function dispatchError(event:flash.events.ErrorEvent):Void;
	private function dispatchProxy(event:flash.events.Event):Void;
}
