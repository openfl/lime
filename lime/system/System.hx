package lime.system;


import lime._backend.native.NativeCFFI;
import lime.app.Application;
import lime.math.Rectangle;

#if flash
import flash.net.URLRequest;
import flash.system.Capabilities;
import flash.Lib;
#end

#if (js && html5)
import js.Browser;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
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
		var displayInfo:Dynamic = NativeCFFI.lime_system_get_display (id);
		
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
			#elseif (js && html5)
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
		return cast NativeCFFI.lime_system_get_timer ();
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
	
	
	public static function openFile (path:String):Void {
		
		if (path != null) {
			
			#if windows
			
			Sys.command ("start", [ path ]);
			
			#elseif mac
			
			Sys.command ("/usr/bin/open", [ path ]);
			
			#elseif linux
			
			Sys.command ("/usr/bin/xdg-open", [ path, "&" ]);
			
			#elseif (js && html5)
			
			Browser.window.open (path, "_blank");
			
			#elseif flash
			
			Lib.getURL (new URLRequest (path), "_blank");
			
			#elseif android
			
			var openFile = JNI.createStaticMethod ("org/haxe/lime/GameActivity", "openFile", "(Ljava/lang/String;)V");
			openFile (path);
			
			#elseif (lime_cffi && !macro)
			
			NativeCFFI.lime_system_open_file (path);
			
			#end
			
		}
		
	}
	
	
	public static function openURL (url:String, target:String = "_blank"):Void {
		
		if (url != null) {
			
			#if desktop
			
			openFile (url);
			
			#elseif (js && html5)
			
			Browser.window.open (url, target);
			
			#elseif flash
			
			Lib.getURL (new URLRequest (url), target);
			
			#elseif android
			
			var openURL = JNI.createStaticMethod ("org/haxe/lime/GameActivity", "openURL", "(Ljava/lang/String;Ljava/lang/String;)V");
			openURL (url, target);
			
			#elseif (lime_cffi && !macro)
			
			NativeCFFI.lime_system_open_url (url, target);
			
			#end
			
		}
		
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
				
				path = NativeCFFI.lime_system_get_directory (type, company, file);
				
			} else {
				
				path = NativeCFFI.lime_system_get_directory (type, null, null);
				
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
		return NativeCFFI.lime_system_get_allow_screen_timeout ();
		#else
		return true;
		#end
		
	}
	
	
	private static function set_allowScreenTimeout (value:Bool):Bool {
		
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_system_set_allow_screen_timeout (value);
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
		return NativeCFFI.lime_system_get_num_displays ();
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
	
	
}


@:enum private abstract SystemDirectory(Int) from Int to Int from UInt to UInt {
	
	var APPLICATION = 0;
	var APPLICATION_STORAGE = 1;
	var DESKTOP = 2;
	var DOCUMENTS = 3;
	var FONTS = 4;
	var USER = 5;
	
}