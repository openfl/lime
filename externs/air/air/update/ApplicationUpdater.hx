package air.update;

extern class ApplicationUpdater // extends air.update.states.HSM {
{
	var configurationFile:flash.filesystem.File;
	var currentState(default, never):String;
	var currentVersion(default, never):String;
	var delay:Float;
	var isFirstRun(default, never):Bool;
	var isNewerVersionFunction:Dynamic;
	var previousApplicationStorageDirectory(default, never):flash.filesystem.File;
	var previousVersion(default, never):String;
	var updateDescriptor(default, never):flash.xml.XML;
	var updateURL:String;
	var wasPendingUpdate(default, never):Bool;
	function new():Void;
	function cancelUpdate():Void;
	function checkForUpdate():Void;
	function checkNow():Void;
	function downloadUpdate():Void;
	function initialize():Void;
	function installFromAIRFile(file:flash.filesystem.File):Void;
	function installUpdate():Void;
	private var configuration:Dynamic; // air.update.core.UpdaterConfiguration;
	private var state:Dynamic; // air.update.core.UpdaterState;
	private var updaterHSM:Dynamic; // air.update.core.UpdaterHSM;
	private function dispatchProxy(event:flash.events.Event):Void;
	private function handleFirstRun():Bool;
	private function handlePeriodicalCheck():Void;
	private function onDownloadComplete(event:air.update.events.UpdateEvent):Void;
	private function onFileInstall():Void;
	private function onFileStatus(event:air.update.events.StatusFileUpdateEvent):Void;
	private function onInitializationComplete():Void;
	private function onInitialize():Void;
	private function onInstall():Void;
	private function onStateClear(event:flash.events.Event):Void;
	private function onTimer(event:flash.events.TimerEvent):Void;
	private function stateCancelled(event:flash.events.Event):Void;
	private function stateInitializing(event:flash.events.Event):Void;
	private function stateReady(event:flash.events.Event):Void;
	private function stateRunning(event:flash.events.Event):Void;
	private function stateUninitialized(event:flash.events.Event):Void;
}
