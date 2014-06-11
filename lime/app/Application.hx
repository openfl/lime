package lime.app;


import lime.graphics.*;
import lime.system.*;
import lime.ui.*;


class Application implements IKeyEventListener implements IMouseEventListener implements IRenderEventListener implements ITouchEventListener implements IUpdateEventListener implements IWindowEventListener {
	
	
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
		RenderEventManager.addEventListener (this);
		TouchEventManager.addEventListener (this);
		UpdateEventManager.addEventListener (this);
		WindowEventManager.addEventListener (this);
		
		var window = new Window (this);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		#if js
		window.element = config.element;
		#end
		
		addWindow (window);
		
	}
	
	
	public function exec ():Int {
		
		#if (cpp || neko)
		return lime_application_exec (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public function onKeyDown (event:KeyEvent):Void {}
	public function onKeyUp (event:KeyEvent):Void {}
	public function onMouseDown (event:MouseEvent):Void {}
	public function onMouseMove (event:MouseEvent):Void {}
	public function onMouseUp (event:MouseEvent):Void {}
	public function onRender (event:RenderEvent):Void {}
	public function onTouchEnd (event:TouchEvent):Void {}
	public function onTouchMove (event:TouchEvent):Void {}
	public function onTouchStart (event:TouchEvent):Void {}
	public function onUpdate (event:UpdateEvent):Void {}
	public function onWindowActivate (event:WindowEvent):Void {}
	public function onWindowDeactivate (event:WindowEvent):Void {}
	
	
	#if (cpp || neko)
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	#end
	
	
}