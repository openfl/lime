package lime._backend.native;


import lime.app.Application;
import lime.graphics.Image;
import lime.system.System;
import lime.ui.Window;

@:access(lime.app.Application)


class NativeWindow {
	
	
	public var handle:Dynamic;
	
	private var parent:Window;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
	}
	
	
	public function close ():Void {
		
		if (handle != null) {
			
			lime_window_close (handle);
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
			if (Reflect.hasField (parent.config, "resizable") && parent.config.resizable) flags |= cast WindowFlags.WINDOW_FLAG_RESIZABLE;
			if (Reflect.hasField (parent.config, "stencilBuffer") && parent.config.stencilBuffer) flags |= cast WindowFlags.WINDOW_FLAG_STENCIL_BUFFER;
			if (Reflect.hasField (parent.config, "vsync") && parent.config.vsync) flags |= cast WindowFlags.WINDOW_FLAG_VSYNC;
			
			if (Reflect.hasField (parent.config, "title")) {
				
				title = parent.config.title;
				
			}
			
		}
		
		handle = lime_window_create (application.backend.handle, parent.width, parent.height, flags, title);
		
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
	
	
	private static var lime_window_close = System.load ("lime", "lime_window_close", 1);
	private static var lime_window_create = System.load ("lime", "lime_window_create", 5);
	private static var lime_window_move = System.load ("lime", "lime_window_move", 3);
	private static var lime_window_resize = System.load ("lime", "lime_window_resize", 3);
	private static var lime_window_set_icon = System.load ("lime", "lime_window_set_icon", 2);
	
	
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