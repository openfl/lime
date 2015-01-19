package lime.ui;


import lime.app.Application;
import lime.app.Config;
import lime.app.Event;
import lime.graphics.Image;
import lime.graphics.Renderer;


class Window {
	
	
	public static var onWindowActivate = new Event<Void->Void> ();
	public static var onWindowClose = new Event<Void->Void> ();
	public static var onWindowDeactivate = new Event<Void->Void> ();
	public static var onWindowFocusIn = new Event<Void->Void> ();
	public static var onWindowFocusOut = new Event<Void->Void> ();
	public static var onWindowMove = new Event<Float->Float->Void> ();
	public static var onWindowResize = new Event<Int->Int->Void> ();
	
	public var currentRenderer:Renderer;
	public var config:Config;
	public var fullscreen:Bool;
	public var height:Int;
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
	@:noCompletion public var backend:WindowBackend;
	
	
	public function new (config:Config) {
		
		this.config = config;
		
		backend = new WindowBackend (this);
		
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