package lime._backend.native;


import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.system.Display;
import lime.system.System;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.ui.Window)


class NativeWindow {
	
	
	public var handle:Dynamic;
	
	private var parent:Window;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
	}
	
	
	public function close ():Void {
		
		if (handle != null) {
			
			lime_window_close.call (handle);
			handle = null;
			
		}
		
	}
	
	
	public function create (application:Application):Void {
		
		var title = "Lime Application";
		var flags = 0;
		
		if (parent.config != null) {
			
			if (Reflect.hasField (parent.config, "antialiasing")) {
				
				if (parent.config.antialiasing >= 4) {
					
					flags |= cast WindowFlags.WINDOW_FLAG_HW_AA_HIRES;
					
				} else if (parent.config.antialiasing >= 2) {
					
					flags |= cast WindowFlags.WINDOW_FLAG_HW_AA;
					
				}
				
			}
			
			if (Reflect.hasField (parent.config, "borderless") && parent.config.borderless) flags |= cast WindowFlags.WINDOW_FLAG_BORDERLESS;
			if (Reflect.hasField (parent.config, "depthBuffer") && parent.config.depthBuffer) flags |= cast WindowFlags.WINDOW_FLAG_DEPTH_BUFFER;
			if (Reflect.hasField (parent.config, "fullscreen") && parent.config.fullscreen) flags |= cast WindowFlags.WINDOW_FLAG_FULLSCREEN;
			if (Reflect.hasField (parent.config, "hardware") && parent.config.hardware) flags |= cast WindowFlags.WINDOW_FLAG_HARDWARE;
			if (Reflect.hasField (parent.config, "resizable") && parent.config.resizable) flags |= cast WindowFlags.WINDOW_FLAG_RESIZABLE;
			if (Reflect.hasField (parent.config, "stencilBuffer") && parent.config.stencilBuffer) flags |= cast WindowFlags.WINDOW_FLAG_STENCIL_BUFFER;
			if (Reflect.hasField (parent.config, "vsync") && parent.config.vsync) flags |= cast WindowFlags.WINDOW_FLAG_VSYNC;
			
			if (Reflect.hasField (parent.config, "title")) {
				
				title = parent.config.title;
				
			}
			
		}
		
		handle = lime_window_create.call (application.backend.handle, parent.width, parent.height, flags, title);
		
		if (handle != null) {
			
			parent.__width = lime_window_get_width.call (handle);
			parent.__height = lime_window_get_height.call (handle);
			parent.__x = lime_window_get_x.call (handle);
			parent.__y = lime_window_get_y.call (handle);
			parent.id = lime_window_get_id.call (handle);
			
		}
		
	}
	
	
	public function focus ():Void {
		
		if (handle != null) {
			
			lime_window_focus.call (handle);
			
		}
		
	}
	
	
	public function getDisplay ():Display {
		
		var center = new Vector2 (parent.__x + (parent.__width / 2), parent.__y + (parent.__height / 2));
		var numDisplays = System.numDisplays;
		var display;
		
		for (i in 0...numDisplays) {
			
			display = System.getDisplay (i);
			
			if (display.bounds.containsPoint (center)) {
				
				return display;
				
			}
			
		}
		
		return null;
		
	}
	
	
	public function getEnableTextEvents ():Bool {
		
		if (handle != null) {
			
			return lime_window_get_enable_text_events.call (handle);
			
		}
		
		return false;
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		if (handle != null) {
			
			lime_window_move.call (handle, x, y);
			
		}
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		if (handle != null) {
			
			lime_window_resize.call (handle, width, height);
			
		}
		
	}
	
	
	public function setEnableTextEvents (value:Bool):Bool {
		
		if (handle != null) {
			
			return lime_window_set_enable_text_events.call (handle, value);
			
		}
		
		return value;
		
	}
	
	
	public function setFullscreen (value:Bool):Bool {
		
		if (handle != null) {
			
			value = lime_window_set_fullscreen.call (handle, value);
			
			if (value) {
				
				parent.onFullscreen.dispatch ();
				
			}
			
		}
		
		return value;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		if (handle != null) {
			
			lime_window_set_icon.call (handle, image.buffer);
			
		}
		
	}
	
	
	public function setMinimized (value:Bool):Bool {
		
		if (handle != null) {
			
			return lime_window_set_minimized.call (handle, value);
			
		}
		
		return value;
		
	}
	
	
	public function setTitle (value:String):String {
		
		if (handle != null) {
			
			return lime_window_set_title.call (handle, value);
			
		}
		
		return value;
		
	}
	
	
	private static var lime_window_close = System.loadPrime ("lime", "lime_window_close", "dv");
	private static var lime_window_create = System.loadPrime ("lime", "lime_window_create", "diiisd");
	private static var lime_window_focus = System.loadPrime ("lime", "lime_window_focus", "dv");
	private static var lime_window_get_enable_text_events = System.loadPrime ("lime", "lime_window_get_enable_text_events", "db");
	private static var lime_window_get_height = System.loadPrime ("lime", "lime_window_get_height", "di");
	private static var lime_window_get_id = System.loadPrime ("lime", "lime_window_get_id", "di");
	private static var lime_window_get_width = System.loadPrime ("lime", "lime_window_get_width", "di");
	private static var lime_window_get_x = System.loadPrime ("lime", "lime_window_get_x", "di");
	private static var lime_window_get_y = System.loadPrime ("lime", "lime_window_get_y", "di");
	private static var lime_window_move = System.loadPrime ("lime", "lime_window_move", "diiv");
	private static var lime_window_resize = System.loadPrime ("lime", "lime_window_resize", "diiv");
	private static var lime_window_set_enable_text_events = System.loadPrime ("lime", "lime_window_set_enable_text_events", "dbv");
	private static var lime_window_set_fullscreen = System.loadPrime ("lime", "lime_window_set_fullscreen", "dbb");
	private static var lime_window_set_icon = System.loadPrime ("lime", "lime_window_set_icon", "dov");
	private static var lime_window_set_minimized = System.loadPrime ("lime", "lime_window_set_minimized", "dbb");
	private static var lime_window_set_title = System.loadPrime ("lime", "lime_window_set_title", "dss");
	
	
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