package lime._backend.native;


import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.Vector2;
import lime.system.Display;
import lime.system.System;
import lime.ui.Window;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(lime.app.Application)
@:access(lime.ui.Window)


class NativeWindow {


	public var handle:Dynamic;

	private var parent:Window;


	public function new (parent:Window) {

		this.parent = parent;

	}


	public function alert (message:String, title:String):Void {

		if (handle != null) {

			#if !macro
			lime_window_alert (handle, message, title);
			#end

		}

	}


	public function close ():Void {

		if (handle != null) {

			#if !macro
			lime_window_close (handle);
			#end
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
		
		#if !macro
		handle = lime_window_create (application.backend.handle, parent.width, parent.height, flags, title);
		
		if (handle != null) {
			
			parent.__width = lime_window_get_width (handle);
			parent.__height = lime_window_get_height (handle);
			parent.__x = lime_window_get_x (handle);
			parent.__y = lime_window_get_y (handle);
			parent.id = lime_window_get_id (handle);
			
		}
		#end
		
	}
	
	
	public function focus ():Void {
		
		if (handle != null) {
			
			#if !macro
			lime_window_focus (handle);
			#end
			
		}
		
	}
	
	
	public function getDisplay ():Display {
		
		if (handle != null) {
			
			var index = lime_window_get_display (handle);
			
			if (index > -1) {
				
				return System.getDisplay (index);
				
			}
			
		}
		
		return null;
		
	}
	
	
	public function getEnableTextEvents ():Bool {
		
		if (handle != null) {
			
			#if !macro
			return lime_window_get_enable_text_events (handle);
			#end
			
		}
		
		return false;
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		if (handle != null) {
			
			#if !macro
			lime_window_move (handle, x, y);
			#end
			
		}
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		if (handle != null) {
			
			#if !macro
			lime_window_resize (handle, width, height);
			#end
			
		}
		
	}
	
	
	public function setBorderless (value:Bool):Bool {
		
		if (handle != null) {
			
			#if !macro
			lime_window_set_borderless (handle, value);
			#end
			
		}
		
		return value;
	}
	
	
	public function setEnableTextEvents (value:Bool):Bool {
		
		if (handle != null) {
			
			#if !macro
			lime_window_set_enable_text_events (handle, value);
			#end
			
		}
		
		return value;
		
	}
	
	
	public function setFullscreen (value:Bool):Bool {
		
		if (handle != null) {
			
			#if !macro
			value = lime_window_set_fullscreen (handle, value);
			#end
			
			if (value) {
				
				parent.onFullscreen.dispatch ();
				
			}
			
		}
		
		return value;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		if (handle != null) {
			
			#if !macro
			lime_window_set_icon (handle, image.buffer);
			#end
			
		}
		
	}
	
	
	public function setMinimized (value:Bool):Bool {
		
		if (handle != null) {
			
			#if !macro
			return lime_window_set_minimized (handle, value);
			#end
			
		}
		
		return value;
		
	}
	
	
	public function setResizable (value:Bool):Bool {
		
		if (handle != null) {
			
			#if !macro
			lime_window_set_resizable (handle, value);
			
			// TODO: remove need for workaround
			
			lime_window_set_borderless (handle, !parent.__borderless);
			lime_window_set_borderless (handle, parent.__borderless);
			#end
			
		}
		
		return value;
	}
	
	
	public function setTitle (value:String):String {
		
		if (handle != null) {
			
			#if !macro
			return lime_window_set_title (handle, value);
			#end
			
		}
		
		return value;
		
	}
	
	public function getScreenWidth():Int {
		throw ":TODO:";
	}

	public function getScreenHeight():Int {
		throw ":TODO:";
	}
	
	#if !macro
	@:cffi private static function lime_window_alert (handle:Dynamic, message:String, title:String):Void;
	@:cffi private static function lime_window_close (handle:Dynamic):Void;
	@:cffi private static function lime_window_create (application:Dynamic, width:Int, height:Int, flags:Int, title:String):Dynamic;
	@:cffi private static function lime_window_focus (handle:Dynamic):Void;
	@:cffi private static function lime_window_get_display (handle:Dynamic):Int;
	@:cffi private static function lime_window_get_enable_text_events (handle:Dynamic):Bool;
	@:cffi private static function lime_window_get_height (handle:Dynamic):Int;
	@:cffi private static function lime_window_get_id (handle:Dynamic):Int;
	@:cffi private static function lime_window_get_width (handle:Dynamic):Int;
	@:cffi private static function lime_window_get_x (handle:Dynamic):Int;
	@:cffi private static function lime_window_get_y (handle:Dynamic):Int;
	@:cffi private static function lime_window_move (handle:Dynamic, x:Int, y:Int):Void;
	@:cffi private static function lime_window_resize (handle:Dynamic, width:Int, height:Int):Void;
	@:cffi private static function lime_window_set_borderless (handle:Dynamic, borderless:Bool):Bool;
	@:cffi private static function lime_window_set_enable_text_events (handle:Dynamic, enabled:Bool):Void;
	@:cffi private static function lime_window_set_fullscreen (handle:Dynamic, fullscreen:Bool):Bool;
	@:cffi private static function lime_window_set_icon (handle:Dynamic, buffer:Dynamic):Void;
	@:cffi private static function lime_window_set_minimized (handle:Dynamic, minimized:Bool):Bool;
	@:cffi private static function lime_window_set_resizable (handle:Dynamic, resizable:Bool):Bool;
	@:cffi private static function lime_window_set_title (handle:Dynamic, title:String):Dynamic;
	#end
	
	
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