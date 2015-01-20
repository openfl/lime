package lime._backend.native;


import lime.app.Application;
import lime.app.Config;
import lime.app.Event;
import lime.graphics.Image;
import lime.graphics.Renderer;
import lime.system.System;
import lime.ui.*;

@:access(lime.ui)


class NativeWindow {
	
	
	private static var eventInfo = new WindowEventInfo ();
	private static var registered:Bool;
	
	public var handle:Dynamic;
	
	private var parent:Window;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
		if (!registered) {
			
			registered = true;
			
			lime_window_event_manager_register (dispatch, eventInfo);
			
		}
		
	}
	
	
	public function create (application:Application):Void {
		
		var flags = 0;
		
		if (parent.config.antialiasing >= 4) {
			
			flags |= cast WindowFlags.WINDOW_FLAG_HW_AA_HIRES;
			
		} else if (parent.config.antialiasing >= 2) {
			
			flags |= cast WindowFlags.WINDOW_FLAG_HW_AA;
			
		}
		
		if (parent.config.borderless) flags |= cast WindowFlags.WINDOW_FLAG_BORDERLESS;
		if (parent.config.depthBuffer) flags |= cast WindowFlags.WINDOW_FLAG_DEPTH_BUFFER;
		if (parent.config.fullscreen) flags |= cast WindowFlags.WINDOW_FLAG_FULLSCREEN;
		if (parent.config.resizable) flags |= cast WindowFlags.WINDOW_FLAG_RESIZABLE;
		if (parent.config.stencilBuffer) flags |= cast WindowFlags.WINDOW_FLAG_STENCIL_BUFFER;
		if (parent.config.vsync) flags |= cast WindowFlags.WINDOW_FLAG_VSYNC;
		
		handle = lime_window_create (application.backend.handle, parent.width, parent.height, flags, parent.config.title);
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case WINDOW_ACTIVATE:
				
				Window.onWindowActivate.dispatch ();
			
			case WINDOW_CLOSE:
				
				Window.onWindowClose.dispatch ();
			
			case WINDOW_DEACTIVATE:
				
				Window.onWindowDeactivate.dispatch ();
			
			case WINDOW_FOCUS_IN:
				
				Window.onWindowFocusIn.dispatch ();
			
			case WINDOW_FOCUS_OUT:
				
				Window.onWindowFocusOut.dispatch ();
			
			case WINDOW_MOVE:
				
				parent.x = eventInfo.x;
				parent.y = eventInfo.y;
				
				Window.onWindowMove.dispatch (eventInfo.x, eventInfo.y);
			
			case WINDOW_RESIZE:
				
				parent.width = eventInfo.width;
				parent.height = eventInfo.height;
				
				Window.onWindowResize.dispatch (eventInfo.width, eventInfo.height);
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		lime_window_move (handle, x, y);
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		lime_window_resize (handle, width, height);
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		lime_window_set_icon (handle, image.buffer);
		
	}
	
	
	private static var lime_window_create = System.load ("lime", "lime_window_create", 5);
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	private static var lime_window_move = System.load ("lime", "lime_window_move", 3);
	private static var lime_window_resize = System.load ("lime", "lime_window_resize", 3);
	private static var lime_window_set_icon = System.load ("lime", "lime_window_set_icon", 2);
	
	
}


private class WindowEventInfo {
	
	
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
	
	public function new (type:WindowEventType = null, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0) {
		
		this.type = type;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type, width, height, x, y);
		
	}
	
	
}


@:enum private abstract WindowFlags(Int) {
	
	var WINDOW_FLAG_FULLSCREEN = 0x00000001;
	var WINDOW_FLAG_BORDERLESS = 0x00000002;
	var WINDOW_FLAG_RESIZABLE = 0x00000004;
	var WINDOW_FLAG_HARDWARE = 0x00000008;
	var WINDOW_FLAG_VSYNC = 0x00000010;
	var WINDOW_FLAG_HW_AA = 0x00000020;
	var WINDOW_FLAG_HW_AA_HIRES = 0x00000060;
	var WINDOW_FLAG_ALLOW_SHADERS = 0x00000080;
	var WINDOW_FLAG_REQUIRE_SHADERS = 0x00000100;
	var WINDOW_FLAG_DEPTH_BUFFER = 0x00000200;
	var WINDOW_FLAG_STENCIL_BUFFER = 0x00000400;
	
}


@:enum private abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_CLOSE = 1;
	var WINDOW_DEACTIVATE = 2;
	var WINDOW_FOCUS_IN = 3;
	var WINDOW_FOCUS_OUT = 4;
	var WINDOW_MOVE = 5;
	var WINDOW_RESIZE = 6;
	
}