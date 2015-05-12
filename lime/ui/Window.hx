package lime.ui;


import lime.app.Application;
import lime.app.Config;
import lime.app.Event;
import lime.graphics.Image;
import lime.graphics.Renderer;


class Window {
	
	
	public var currentRenderer:Renderer;
	public var config:Config;
	public var enableTextEvents (get, set):Bool;
	public var fullscreen (get, set):Bool;
	public var height (get, set):Int;
	public var minimized (get, set):Bool;
	public var onGamepadAxisMove = new Event<Gamepad->GamepadAxis->Float->Void> ();
	public var onGamepadButtonDown = new Event<Gamepad->GamepadButton->Void> ();
	public var onGamepadButtonUp = new Event<Gamepad->GamepadButton->Void> ();
	public var onGamepadConnect = new Event<Gamepad->Void> ();
	public var onGamepadDisconnect = new Event<Gamepad->Void> ();
	public var onKeyDown = new Event<KeyCode->KeyModifier->Void> ();
	public var onKeyUp = new Event<KeyCode->KeyModifier->Void> ();
	public var onMouseDown = new Event<Float->Float->Int->Void> ();
	public var onMouseMove = new Event<Float->Float->Void> ();
	public var onMouseMoveRelative = new Event<Float->Float->Void> ();
	public var onMouseUp = new Event<Float->Float->Int->Void> ();
	public var onMouseWheel = new Event<Float->Float->Void> ();
	public var onTextEdit = new Event<String->Int->Int->Void> ();
	public var onTextInput = new Event<String->Void> ();
	public var onTouchEnd = new Event<Float->Float->Int->Void> ();
	public var onTouchMove = new Event<Float->Float->Int->Void> ();
	public var onTouchStart = new Event<Float->Float->Int->Void> ();
	public var onWindowActivate = new Event<Void->Void> ();
	public var onWindowClose = new Event<Void->Void> ();
	public var onWindowDeactivate = new Event<Void->Void> ();
	public var onWindowEnter = new Event<Void->Void> ();
	public var onWindowFocusIn = new Event<Void->Void> ();
	public var onWindowFocusOut = new Event<Void->Void> ();
	public var onWindowFullscreen = new Event<Void->Void> ();
	public var onWindowLeave = new Event<Void->Void> ();
	public var onWindowMinimize = new Event<Void->Void> ();
	public var onWindowMove = new Event<Float->Float->Void> ();
	public var onWindowResize = new Event<Int->Int->Void> ();
	public var onWindowRestore = new Event<Void->Void> ();
	public var width (get, set):Int;
	public var x (get, set):Int;
	public var y (get, set):Int;
	
	@:noCompletion private var backend:WindowBackend;
	@:noCompletion private var __fullscreen:Bool;
	@:noCompletion private var __height:Int;
	@:noCompletion private var __minimized:Bool;
	@:noCompletion private var __width:Int;
	@:noCompletion private var __x:Int;
	@:noCompletion private var __y:Int;
	
	
	public function new (config:Config = null) {
		
		this.config = config;
		
		__width = 0;
		__height = 0;
		__fullscreen = false;
		__x = 0;
		__y = 0;
		
		if (config != null) {
			
			// TODO: Switch to the tool's Config type?
			
			if (Reflect.hasField (config, "width")) __width = config.width;
			if (Reflect.hasField (config, "height")) __height = config.height;
			if (Reflect.hasField (config, "fullscreen")) __fullscreen = config.fullscreen;
			
		}
		
		backend = new WindowBackend (this);
		
	}
	
	
	public function close ():Void {
		
		backend.close ();
		
	}
	
	
	public function create (application:Application):Void {
		
		backend.create (application);
		
		if (currentRenderer != null) {
			
			currentRenderer.create ();
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		backend.move (x, y);
		
		__x = x;
		__y = y;
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		backend.resize (width, height);
		
		__width = width;
		__height = height;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		if (image == null) {
			
			return;
			
		}
		
		backend.setIcon (image);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_enableTextEvents ():Bool {
		
		return backend.getEnableTextEvents ();
		
	}
	
	
	@:noCompletion private inline function set_enableTextEvents (value:Bool):Bool {
		
		return backend.setEnableTextEvents (value);
		
	}
	
	
	@:noCompletion private inline function get_fullscreen ():Bool {
		
		return __fullscreen;
		
	}
	
	
	@:noCompletion private function set_fullscreen (value:Bool):Bool {
		
		return __fullscreen = backend.setFullscreen (value);
		
	}
	
	
	@:noCompletion private inline function get_height ():Int {
		
		return __height;
		
	}
	
	
	@:noCompletion private function set_height (value:Int):Int {
		
		resize (__width, value);
		return __height;
		
	}
	
	
	@:noCompletion private inline function get_minimized ():Bool {
		
		return __minimized;
		
	}
	
	
	@:noCompletion private function set_minimized (value:Bool):Bool {
		
		return __minimized = backend.setMinimized (value);
		
	}
	
	
	@:noCompletion private inline function get_width ():Int {
		
		return __width;
		
	}
	
	
	@:noCompletion private function set_width (value:Int):Int {
		
		resize (value, __height);
		return __width;
		
	}
	
	
	@:noCompletion private inline function get_x ():Int {
		
		return __x;
		
	}
	
	
	@:noCompletion private function set_x (value:Int):Int {
		
		move (value, __y);
		return __x;
		
	}
	
	
	@:noCompletion private inline function get_y ():Int {
		
		return __y;
		
	}
	
	
	@:noCompletion private function set_y (value:Int):Int {
		
		move (__x, value);
		return __y;
		
	}
	
	
}


#if flash
@:noCompletion private typedef WindowBackend = lime._backend.flash.FlashWindow;
#elseif (js && html5)
@:noCompletion private typedef WindowBackend = lime._backend.html5.HTML5Window;
#else
@:noCompletion private typedef WindowBackend = lime._backend.native.NativeWindow;
#end