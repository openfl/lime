package lime.app;


import lime.ui.IMouseEventListener;
import lime.ui.ITouchEventListener;
import lime.ui.MouseEvent;
import lime.ui.TouchEvent;
import lime.system.System;


class Application implements IMouseEventListener implements ITouchEventListener {
	
	
	public var handle:Dynamic;
	
	
	public function new () {
		
		
		
	}
	
	
	public function create (config:Config) {
		
		#if (cpp || neko)
		handle = lime_application_create ();
		#end
		
		var window = new Window (this);
		var renderer = new Renderer (window);
		
	}
	
	
	public function exec () {
		
		#if (cpp || neko)
		return lime_application_exec (handle);
		#end
		
	}
	
	
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