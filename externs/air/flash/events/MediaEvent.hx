package flash.events;

extern class MediaEvent extends Event {
	var data(default,never) : flash.media.MediaPromise;
	function new(type : String, bubbles : Bool=false, cancelable : Bool=false, ?data : flash.media.MediaPromise) : Void;
	static var COMPLETE : String;
	static var SELECT : String;
}
