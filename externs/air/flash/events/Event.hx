package flash.events;

extern class Event
{
	var bubbles(default, never):Bool;
	var cancelable(default, never):Bool;
	var currentTarget(default, never):Dynamic;
	var eventPhase(default, never):EventPhase;
	var target(default, never):Dynamic;
	var type(default, never):String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false):Void;
	function clone():Event;
	function formatToString(className:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):String;
	function isDefaultPrevented():Bool;
	function preventDefault():Void;
	function stopImmediatePropagation():Void;
	function stopPropagation():Void;
	function toString():String;
	static var ACTIVATE(default, never):String;
	static var ADDED(default, never):String;
	static var ADDED_TO_STAGE(default, never):String;
	static var BROWSER_ZOOM_CHANGE(default, never):String;
	static var CANCEL(default, never):String;
	static var CHANGE(default, never):String;
	static var CHANNEL_MESSAGE(default, never):String;
	static var CHANNEL_STATE(default, never):String;
	@:require(flash10) static var CLEAR(default, never):String;
	static var CLOSE(default, never):String;
	#if air
	static var CLOSING(default, never):String;
	#end
	static var COMPLETE(default, never):String;
	static var CONNECT(default, never):String;
	@:require(flash11) static var CONTEXT3D_CREATE(default, never):String;
	@:require(flash10) static var COPY(default, never):String;
	@:require(flash10) static var CUT(default, never):String;
	static var DEACTIVATE(default, never):String;
	#if air
	static var DISPLAYING(default, never):String;
	#end
	static var ENTER_FRAME(default, never):String;
	#if air
	static var EXITING(default, never):String;
	#end
	@:require(flash10) static var EXIT_FRAME(default, never):String;
	@:require(flash10) static var FRAME_CONSTRUCTED(default, never):String;
	@:require(flash11_3) static var FRAME_LABEL(default, never):String;
	static var FULLSCREEN(default, never):String;
	#if air
	static var HTML_BOUNDS_CHANGE(default, never):String;
	static var HTML_DOM_INITIALIZE(default, never):String;
	static var HTML_RENDER(default, never):String;
	#end
	static var ID3(default, never):String;
	static var INIT(default, never):String;
	#if air
	static var LOCATION_CHANGE(default, never):String;
	#end
	static var MOUSE_LEAVE(default, never):String;
	#if air
	static var NETWORK_CHANGE(default, never):String;
	#end
	static var OPEN(default, never):String;
	@:require(flash10) static var PASTE(default, never):String;
	#if air
	static var PREPARING(default, never):String;
	#end
	static var REMOVED(default, never):String;
	static var REMOVED_FROM_STAGE(default, never):String;
	static var RENDER(default, never):String;
	static var RESIZE(default, never):String;
	static var SCROLL(default, never):String;
	static var SELECT(default, never):String;
	@:require(flash10) static var SELECT_ALL(default, never):String;
	static var SOUND_COMPLETE(default, never):String;
	#if air
	static var STANDARD_ERROR_CLOSE(default, never):String;
	static var STANDARD_INPUT_CLOSE(default, never):String;
	static var STANDARD_OUTPUT_CLOSE(default, never):String;
	#end
	@:require(flash11_3) static var SUSPEND(default, never):String;
	static var TAB_CHILDREN_CHANGE(default, never):String;
	static var TAB_ENABLED_CHANGE(default, never):String;
	static var TAB_INDEX_CHANGE(default, never):String;
	@:require(flash11_3) static var TEXTURE_READY(default, never):String;
	@:require(flash11) static var TEXT_INTERACTION_MODE_CHANGE(default, never):String;
	static var UNLOAD(default, never):String;
	#if air
	static var USER_IDLE(default, never):String;
	static var USER_PRESENT(default, never):String;
	#end
	static var VIDEO_FRAME(default, never):String;
	static var WORKER_STATE(default, never):String;
}
