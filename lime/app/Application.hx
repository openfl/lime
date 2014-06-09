package lime.app;


import lime.ui.IKeyEventListener;
import lime.ui.IMouseEventListener;
import lime.ui.ITouchEventListener;
import lime.ui.IWindowEventListener;
import lime.ui.KeyEventManager;
import lime.ui.KeyEvent;
import lime.ui.MouseEventManager;
import lime.ui.MouseEvent;
import lime.ui.TouchEventManager;
import lime.ui.TouchEvent;
import lime.ui.WindowEventManager;
import lime.ui.WindowEvent;
import lime.system.System;


class Application implements IKeyEventListener implements IMouseEventListener implements IRenderEventListener implements ITouchEventListener implements IUpdateEventListener implements IWindowEventListener {
	
	
	public var handle:Dynamic;
	
	private var lastUpdate:Int;
	
	
	public function new () {
		
		lastUpdate = 0;
		
	}
	
	
	public function create (config:Config) {
		
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
		
	}
	
	
	public function exec () {
		
		#if (cpp || neko)
		return lime_application_exec (handle);
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