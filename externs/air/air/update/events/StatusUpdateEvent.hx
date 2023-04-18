package air.update.events;

extern class StatusUpdateEvent extends UpdateEvent
{
	var available:Bool;
	var details:Array<Dynamic>;
	var version:String;
	var versionLabel:String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, available:Bool = false, version:String = "", ?details:Array<Dynamic>,
		versionLabel:String = ""):Void;
	static var UPDATE_STATUS(default, never):String;
}
