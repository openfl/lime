package lime.ui;


import lime.app.Application;
import lime.app.Config;
import lime.app.Event;
import lime.graphics.Image;
import lime.graphics.Renderer;


class Window {
	
	
	public var currentRenderer:Renderer;
	public var config:Config;
	public var fullscreen:Bool;
	public var height:Int;
	public var onKeyDown = new Event<Int->Int->Void> ();
	public var onKeyUp = new Event<Int->Int->Void> ();
	public var onMouseDown = new Event<Float->Float->Int->Void> ();
	public var onMouseMove = new Event<Float->Float->Int->Void> ();
	public var onMouseUp = new Event<Float->Float->Int->Void> ();
	public var onMouseWheel = new Event<Float->Float->Void> ();
	public var onTouchEnd = new Event<Float->Float->Int->Void> ();
	public var onTouchMove = new Event<Float->Float->Int->Void> ();
	public var onTouchStart = new Event<Float->Float->Int->Void> ();
	public var onWindowActivate = new Event<Void->Void> ();
	public var onWindowClose = new Event<Void->Void> ();
	public var onWindowDeactivate = new Event<Void->Void> ();
	public var onWindowFocusIn = new Event<Void->Void> ();
	public var onWindowFocusOut = new Event<Void->Void> ();
	public var onWindowMove = new Event<Float->Float->Void> ();
	public var onWindowResize = new Event<Int->Int->Void> ();
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
	@:noCompletion private var backend:WindowBackend;
	
	
	public function new (config:Config = null) {
		
		this.config = config;
		
		width = 0;
		height = 0;
		fullscreen = false;
		x = 0;
		y = 0;
		
		if (config != null) {
			
			// TODO: Switch to the tool's Config type?
			
			if (Reflect.hasField (config, "width")) width = config.width;
			if (Reflect.hasField (config, "height")) height = config.height;
			if (Reflect.hasField (config, "fullscreen")) fullscreen = config.fullscreen;
			
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
		
		this.x = x;
		this.y = y;
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		backend.resize (width, height);
		
		this.width = width;
		this.height = height;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		if (image == null) {
			
			return;
			
		}
		
		backend.setIcon (image);
		
	}
	
	
}


#if flash
@:noCompletion private typedef WindowBackend = lime._backend.flash.FlashWindow;
#elseif (js && html5)
@:noCompletion private typedef WindowBackend = lime._backend.html5.HTML5Window;
#else
@:noCompletion private typedef WindowBackend = lime._backend.native.NativeWindow;
#end