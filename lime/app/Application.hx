package lime.app;


import lime.graphics.*;
import lime.system.*;
import lime.ui.*;


class Application implements IKeyEventListener implements IMouseEventListener implements ITouchEventListener implements IWindowEventListener {
		
	public var handle:Dynamic;
	
	private var config:Config;
	private var lastUpdate:Int;
	private var windows:Array<Window>;
	
	
	public function new () {
		
		lastUpdate = 0;
		windows = new Array ();
		
	}
	
	
	public function addWindow (window:Window):Void {
		
		windows.push (window);
		window.create ();
		
	}
	
	
	public function create (config:Config):Void {
		
		this.config = config;
		
		#if (cpp || neko)
		handle = lime_application_create (null);
		#end
		
		new KeyEventManager ();
		new MouseEventManager ();
		new RenderEventManager ();
		new TouchEventManager ();
		new UpdateEventManager ();
		new WindowEventManager ();
		
		KeyEventManager.addEventListener (this);
		MouseEventManager.addEventListener (this);
		TouchEventManager.addEventListener (this);
		WindowEventManager.addEventListener (this);
		
		var window = new Window (this, config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		#if js
		window.element = config.element;
		#end
		
		addWindow (window);
		
		var eventDelegate = new EventDelegate (this);
		
	}
	
	
	public function exec ():Int {
		
		#if (cpp || neko)
		return lime_application_exec (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public function onKeyDown (keyCode:Int, modifier:Int):Void {}
	public function onKeyUp (keyCode:Int, modifier:Int):Void {}
	public function onMouseDown (x:Float, y:Float):Void {}
	public function onMouseMove (x:Float, y:Float):Void {}
	public function onMouseUp (x:Float, y:Float):Void {}
	public function onTouchEnd (x:Float, y:Float):Void {}
	public function onTouchMove (x:Float, y:Float):Void {}
	public function onTouchStart (x:Float, y:Float):Void {}
	public function onWindowActivate ():Void {}
	public function onWindowDeactivate ():Void { }
	
	
	public function render (context:RenderContext):Void {
		
		
		
	}
	
	
	public function update (deltaTime:Int):Void {
		
		
		
	}
	
	
	#if (cpp || neko)
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	#end
	
	
}


@:access(lime.app.Application)
private class EventDelegate implements IRenderEventListener implements IUpdateEventListener {
	
	
	private var application:Application;
	
	
	public function new (application:Application) {
		
		this.application = application;
		
		RenderEventManager.addEventListener (this, -9999999);
		UpdateEventManager.addEventListener (this, -9999999);
		
	}
	
	
	public function onRender (context:RenderContext):Void {
		
		for (window in application.windows) {
			
			if (window.currentRenderer != null) {
				
				application.render (window.currentRenderer.context);
				window.currentRenderer.flip ();
				
			}
			
		}
		
		#if (js && stats)
		application.windows[0].stats.end ();
		#end
		
	}
	
	
	public function onUpdate (deltaTime:Int):Void {
		
		#if (js && stats)
		application.windows[0].stats.begin ();
		#end
		
		application.update (deltaTime);
		
	}
	
	
}