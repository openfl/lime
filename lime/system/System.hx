package lime.system;


import lime.app.Application;
import lime.math.Rectangle;

#if flash
import flash.system.Capabilities;
import flash.Lib;
#end

#if (js && html5)
#if (haxe_ver >= 3.2)
import js.html.Element;
#else
import js.html.HtmlElement;
#end
import js.Browser;
#end

#if (sys && !html5)
import sys.io.Process;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(lime.system.Display)
@:access(lime.system.DisplayMode)


class System {
	
	
	public static var allowScreenTimeout (get, set):Bool;
	public static var applicationDirectory (get, null):String;
	public static var applicationStorageDirectory (get, null):String;
	public static var desktopDirectory (get, null):String;
	public static var disableCFFI:Bool;
	public static var documentsDirectory (get, null):String;
	public static var endianness (get, null):Endian;
	public static var fontsDirectory (get, null):String;
	public static var numDisplays (get, null):Int;
	public static var userDirectory (get, null):String;
	
	@:noCompletion private static var __directories = new Map<SystemDirectory, String> ();
	
	
	#if (js && html5)
	@:keep @:expose("lime.embed")
	public static function embed (element:Dynamic, width:Null<Int> = null, height:Null<Int> = null, background:String = null, assetsPrefix:String = null) {
		
		var htmlElement:#if (haxe_ver >= 3.2) Element #else HtmlElement #end = null;
		
		if (Std.is (element, String)) {
			
			htmlElement = cast Browser.document.getElementById (cast (element, String));
			
		} else if (element == null) {
			
			htmlElement = cast Browser.document.createElement ("div");
			
		} else {
			
			htmlElement = cast element;
			
		}
		
		var color = null;
		
		if (background != null && background != "") {
			
			background = StringTools.replace (background, "#", "");
			
			if (background.indexOf ("0x") > -1) {
				
				color = Std.parseInt (background);
				
			} else {
				
				color = Std.parseInt ("0x" + background);
				
			}
			
		}
		
		if (width == null) {
			
			width = 0;
			
		}
		
		if (height == null) {
			
			height = 0;
			
		}
		
		#if tools
		ApplicationMain.config.windows[0].background = color;
		ApplicationMain.config.windows[0].element = htmlElement;
		ApplicationMain.config.windows[0].width = width;
		ApplicationMain.config.windows[0].height = height;
		ApplicationMain.config.assetsPrefix = assetsPrefix;
		ApplicationMain.create ();
		#end
		
	}
	#end
	
	
	public static function exit (code:Int):Void {
		
		#if android
		
		if (code == 0) {
			
			var mainActivity = JNI.createStaticField ("org/haxe/extension/Extension", "mainActivity", "Landroid/app/Activity;");
			var moveTaskToBack = JNI.createMemberMethod ("android/app/Activity", "moveTaskToBack", "(Z)Z");
			
			moveTaskToBack (mainActivity.get (), true);
			
		}
		
		#end
		
		#if (sys && !macro)
		
		if (Application.current != null) {
			
			// TODO: Clean exit?
			
			Application.current.onExit.dispatch (code);
			
			if (Application.current.onExit.canceled) {
				
				return;
				
			}
			
		}
		
		Sys.exit (code);
		
		#end
		
	}
	
	
	public static function getDisplay (id:Int):Display {
		
		#if (lime_cffi && !macro)
		var displayInfo:Dynamic = lime_system_get_display (id);
		
		if (displayInfo != null) {
			
			var display = new Display ();
			display.id = id;
			display.name = displayInfo.name;
			display.bounds = new Rectangle (displayInfo.bounds.x, displayInfo.bounds.y, displayInfo.bounds.width, displayInfo.bounds.height);
			display.dpi = displayInfo.dpi;
			
			display.supportedModes = [];
			
			var displayMode;
			
			for (mode in cast (displayInfo.supportedModes, Array<Dynamic>)) {
				
				displayMode = new DisplayMode (mode.width, mode.height, mode.refreshRate, mode.pixelFormat);
				display.supportedModes.push (displayMode);
				
			}
			
			if (Reflect.hasField (displayInfo, "currentMode")) {
				
				display.currentMode = display.supportedModes[displayInfo.currentMode];
				
			} else {
				
				display.currentMode = new DisplayMode (0, 0, 60, ARGB32);
				
			}
			
			return display;
			
		}
		#elseif (flash || html5)
		if (id == 0) {
			
			var display = new Display ();
			display.id = 0;
			display.name = "Generic Display";
			
			#if flash
			display.dpi = Capabilities.screenDPI;
			display.currentMode = new DisplayMode (Std.int (Capabilities.screenResolutionX), Std.int (Capabilities.screenResolutionY), 60, ARGB32);
			#else
			display.dpi = 96; // TODO: Detect DPI on HTML5
			display.currentMode = new DisplayMode (Browser.window.screen.width, Browser.window.screen.height, 60, ARGB32);
			#end
			
			display.supportedModes = [ display.currentMode ];
			display.bounds = new Rectangle (0, 0, display.currentMode.width, display.currentMode.height);
			return display;
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function getTimer ():Int {
		
		#if flash
		return flash.Lib.getTimer ();
		#elseif js
		return cast Date.now ().getTime ();
		#elseif (!disable_cffi && !macro)
		return cast lime_system_get_timer ();
		#elseif cpp
		return Std.int (untyped __global__.__time_stamp () * 1000);
		#elseif sys
		return Std.int (Sys.time () * 1000);
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function load (library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic {
		
		#if !macro
		return CFFI.load (library, method, args, lazy);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private static function __getDirectory (type:SystemDirectory):String {
		
		#if (lime_cffi && !macro)
		
		if (__directories.exists (type)) {
			
			return __directories.get (type);
			
		} else {
			
			var path:String;
			
			if (type == APPLICATION_STORAGE) {
				
				var company = "MyCompany";
				var file = "MyApplication";
				
				if (Application.current != null && Application.current.config != null) {
					
					if (Application.current.config.company != null) {
						
						company = Application.current.config.company;
						
					}
					
					if (Application.current.config.file != null) {
						
						file = Application.current.config.file;
						
					}
					
				}
				
				path = lime_system_get_directory (type, company, file);
				
			} else {
				
				path = lime_system_get_directory (type, null, null);
				
			}
			
			#if windows
			var seperator = "\\";
			#else
			var seperator = "/";
			#end
			
			if (path != null && path.length > 0 && !StringTools.endsWith (path, seperator)) {
				
				path += seperator;
				
			}
			
			__directories.set (type, path);
			return path;
			
		}
		
		#elseif flash
		
		if (type != FONTS && Capabilities.playerType == "Desktop") {
			
			var propertyName = switch (type) {
				
				case APPLICATION: "applicationDirectory";
				case APPLICATION_STORAGE: "applicationStorageDirectory";
				case DESKTOP: "desktopDirectory";
				case DOCUMENTS: "documentsDirectory";
				default: "userDirectory";
				
			}
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), propertyName).nativePath;
			
		}
		
		#end
		
		return null;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_allowScreenTimeout ():Bool {
		
		#if (lime_cffi && !macro)
		return lime_system_get_allow_screen_timeout ();
		#else
		return true;
		#end
		
	}
	
	
	private static function set_allowScreenTimeout (value:Bool):Bool {
		
		#if (lime_cffi && !macro)
		return lime_system_set_allow_screen_timeout (value);
		#else
		return true;
		#end
		
	}
	
	
	private static function get_applicationDirectory ():String {
		
		return __getDirectory (APPLICATION);
		
	}
	
	
	private static function get_applicationStorageDirectory ():String {
		
		return __getDirectory (APPLICATION_STORAGE);
		
	}
	
	
	private static function get_desktopDirectory ():String {
		
		return __getDirectory (DESKTOP);
		
	}
	
	
	private static function get_documentsDirectory ():String {
		
		return __getDirectory (DOCUMENTS);
		
	}
	
	
	private static function get_fontsDirectory ():String {
		
		return __getDirectory (FONTS);
		
	}
	
	
	private static function get_numDisplays ():Int {
		
		#if (lime_cffi && !macro)
		return lime_system_get_num_displays ();
		#else
		return 1;
		#end
		
	}
	
	
	private static function get_userDirectory ():String {
		
		return __getDirectory (USER);
		
	}
	
	
	private static function get_endianness ():Endian {
		
		// TODO: Make this smarter
		
		#if (ps3 || wiiu)
		return BIG_ENDIAN;
		#else
		return LITTLE_ENDIAN;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_system_get_allow_screen_timeout ():Bool;
	@:cffi private static function lime_system_set_allow_screen_timeout (value:Bool):Bool;
	@:cffi private static function lime_system_get_directory (type:Int, company:String, title:String):Dynamic;
	@:cffi private static function lime_system_get_display (index:Int):Dynamic;
	@:cffi private static function lime_system_get_num_displays ():Int;
	@:cffi private static function lime_system_get_timer ():Float;
	#end
	
	
}


@:enum private abstract SystemDirectory(Int) from Int to Int from UInt to UInt {
	
	var APPLICATION = 0;
	var APPLICATION_STORAGE = 1;
	var DESKTOP = 2;
	var DOCUMENTS = 3;
	var FONTS = 4;
	var USER = 5;
	
}