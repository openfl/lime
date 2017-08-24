package flash.media;

extern class CameraUI extends flash.events.EventDispatcher {
	function new() : Void;
	function launch(requestedMediaType : String) : Void;
	static var isSupported(default,never) : Bool;
}
