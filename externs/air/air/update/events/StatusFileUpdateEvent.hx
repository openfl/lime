package air.update.events;

extern class StatusFileUpdateEvent extends UpdateEvent
{
	var available:Bool;
	var path:String;
	var version:String;
	var versionLabel:String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, available:Bool = false, version:String = "", path:String = "",
		versionLabel:String = ""):Void;
	static var FILE_UPDATE_STATUS(default, never):String;
}
