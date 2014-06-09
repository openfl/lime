package lime.app;


import lime.ui.IKeyEventListener;
import lime.ui.IMouseEventListener;
import lime.ui.ITouchEventListener;
import lime.ui.KeyEventManager;
import lime.ui.KeyEvent;
import lime.ui.MouseEventManager;
import lime.ui.MouseEvent;
import lime.ui.TouchEventManager;
import lime.ui.TouchEvent;
import lime.system.System;


class Application implements IKeyEventListener implements IMouseEventListener implements ITouchEventListener {
	
	
	public var handle:Dynamic;
	
	
	public function new () {
		
		
		
	}
	
	
	public function create (config:Config) {
		
		#if (cpp || neko)
		handle = lime_application_create ();
		#end
		
		new KeyEventManager ();
		new MouseEventManager ();
		new TouchEventManager ();
		
		KeyEventManager.addEventListener (this);
		MouseEventManager.addEventListener (this);
		TouchEventManager.addEventListener (this);
		
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
	public function onTouchEnd (event:TouchEvent):Void {}
	public function onTouchMove (event:TouchEvent):Void {}
	public function onTouchStart (event:TouchEvent):Void {}
	
	
	
	public function render ():Void {
		
		
		
	}
	
	
	public function update ():Void {
		
		
		
	}
	
	
	
	#if (cpp || neko)
	private static var lime_application_create = System.load ("lime", "lime_application_create", 0);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	#end
	
	
}