package flash.display;

extern class NativeWindow extends flash.events.EventDispatcher
{
	var active(default, never):Bool;
	var alwaysInFront:Bool;
	var bounds:flash.geom.Rectangle;
	var closed(default, never):Bool;
	var displayState(default, never):NativeWindowDisplayState;
	var height:Float;
	var maxSize:flash.geom.Point;
	var maximizable(default, never):Bool;
	var menu:NativeMenu;
	var minSize:flash.geom.Point;
	var minimizable(default, never):Bool;
	var owner(default, never):NativeWindow;
	var renderMode(default, never):NativeWindowRenderMode;
	var resizable(default, never):Bool;
	var stage(default, never):Stage;
	var systemChrome(default, never):NativeWindowSystemChrome;
	var title:String;
	var transparent(default, never):Bool;
	var type(default, never):NativeWindowType;
	var visible:Bool;
	var width:Float;
	var x:Float;
	var y:Float;
	function new(initOptions:NativeWindowInitOptions):Void;
	function activate():Void;
	function close():Void;
	function globalToScreen(globalPoint:flash.geom.Point):flash.geom.Point;
	function listOwnedWindows():flash.Vector<NativeWindow>;
	function maximize():Void;
	function minimize():Void;
	function notifyUser(type:flash.desktop.NotificationType):Void;
	function orderInBackOf(window:NativeWindow):Bool;
	function orderInFrontOf(window:NativeWindow):Bool;
	function orderToBack():Bool;
	function orderToFront():Bool;
	function restore():Void;
	function startMove():Bool;
	function startResize(?edgeOrCorner:NativeWindowResize = NativeWindowResize.BOTTOM_RIGHT):Bool;
	static var isSupported(default, never):Bool;
	static var supportsMenu(default, never):Bool;
	static var supportsNotification(default, never):Bool;
	static var supportsTransparency(default, never):Bool;
	static var systemMaxSize(default, never):flash.geom.Point;
	static var systemMinSize(default, never):flash.geom.Point;
}
