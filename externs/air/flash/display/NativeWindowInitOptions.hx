package flash.display;

extern class NativeWindowInitOptions
{
	#if (haxe_ver < 4.3)
	var maximizable:Bool;
	var minimizable:Bool;
	var owner:NativeWindow;
	var renderMode:NativeWindowRenderMode;
	var resizable:Bool;
	var systemChrome:NativeWindowSystemChrome;
	var transparent:Bool;
	var type:NativeWindowType;
	#else
	@:flash.property var maximizable(get, set):Bool;
	@:flash.property var minimizable(get, set):Bool;
	@:flash.property var owner(get, set):NativeWindow;
	@:flash.property var renderMode(get, set):NativeWindowRenderMode;
	@:flash.property var resizable(get, set):Bool;
	@:flash.property var systemChrome(get, set):NativeWindowSystemChrome;
	@:flash.property var transparent(get, set):Bool;
	@:flash.property var type(get, set):NativeWindowType;
	#end

	function new():Void;

	#if (haxe_ver >= 4.3)
	private function get_maximizable():Bool;
	private function get_minimizable():Bool;
	private function get_owner():NativeWindow;
	private function get_renderMode():NativeWindowRenderMode;
	private function get_resizable():Bool;
	private function get_systemChrome():NativeWindowSystemChrome;
	private function get_transparent():Bool;
	private function get_type():NativeWindowType;
	private function set_maximizable(value:Bool):Bool;
	private function set_minimizable(value:Bool):Bool;
	private function set_owner(value:NativeWindow):NativeWindow;
	private function set_renderMode(value:NativeWindowRenderMode):NativeWindowRenderMode;
	private function set_resizable(value:Bool):Bool;
	private function set_systemChrome(value:NativeWindowSystemChrome):NativeWindowSystemChrome;
	private function set_transparent(value:Bool):Bool;
	private function set_type(value:NativeWindowType):NativeWindowType;
	#end
}
