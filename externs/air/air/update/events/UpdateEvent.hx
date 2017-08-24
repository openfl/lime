package air.update.events;

extern class UpdateEvent extends flash.events.Event {
	function new(type : String, bubbles : Bool=false, cancelable : Bool=false) : Void;
	static var BEFORE_INSTALL : String;
	static var CHECK_FOR_UPDATE : String;
	static var DOWNLOAD_COMPLETE : String;
	static var DOWNLOAD_START : String;
	static var INITIALIZED : String;
}
