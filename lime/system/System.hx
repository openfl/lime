package lime.system;


import haxe.Constraints;
import lime._backend.native.NativeCFFI;
import lime.app.Application;
import lime.app.Config;
import lime.math.Rectangle;
import lime.utils.ArrayBuffer;
import lime.utils.UInt8Array;
import lime.utils.UInt16Array;

#if flash
import flash.net.URLRequest;
import flash.system.Capabilities;
import flash.Lib;
#end

#if air
import flash.desktop.NativeApplication;
#end

#if (js && html5)
import js.html.Element;
import js.Browser;
#end

#if sys
import sys.io.Process;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime.system.Display)
@:access(lime.system.DisplayMode)

#if (cpp && windows && !lime_disable_gpu_hint)
@:cppFileCode('
#if defined(HX_WINDOWS)
extern "C" {
	_declspec(dllexport) unsigned long NvOptimusEnablement = 0x00000001;
	_declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}
#endif
')
#end


class System {
	
	
	public static var allowScreenTimeout (get, set):Bool;
	public static var applicationDirectory (get, null):String;
	public static var applicationStorageDirectory (get, null):String;
	public static var desktopDirectory (get, null):String;
	public static var disableCFFI:Bool;
	public static var documentsDirectory (get, null):String;
	public static var endianness (get, null):Endian;
	public static var fontsDirectory (get, null):String;
	public static var manufacturer (get, null):String;
	public static var model (get, null):String;
	public static var numDisplays (get, null):Int;
	public static var userDirectory (get, null):String;
	public static var version (get, null):String;
	
	@:noCompletion private static var __applicationConfig:Map<String, Config>;
	@:noCompletion private static var __applicationEntryPoint:Map<String, Function>;
	@:noCompletion private static var __directories = new Map<SystemDirectory, String> ();
	
	
	#if (js && html5)
	@:keep @:expose("lime.embed")
	public static function embed (projectName:String, element:Dynamic, width:Null<Int> = null, height:Null<Int> = null, windowConfig:Dynamic = null):Void {
		
		if (__applicationEntryPoint == null || __applicationConfig == null) return;
		
		if (__applicationEntryPoint.exists (projectName)) {
			
			var htmlElement:Element = null;
			
			if (Std.is (element, String)) {
				
				htmlElement = cast Browser.document.getElementById (element);
				
			} else if (element == null) {
				
				htmlElement = cast Browser.document.createElement ("div");
				
			} else {
				
				htmlElement = cast element;
				
			}
			
			if (htmlElement == null) {
				
				Browser.window.console.log ("[lime.embed] ERROR: Cannot find target element: " + element);
				return;
				
			}
			
			if (width == null) {
				
				width = 0;
				
			}
			
			if (height == null) {
				
				height = 0;
				
			}
			
			var defaultConfig = __applicationConfig[projectName];
			var config:Config = {};
			
			__copyMissingFields (config, defaultConfig);
			
			if (windowConfig != null) {
				
				config.windows = [];
				
				if (Std.is (windowConfig, Array)) {
					
					config.windows = windowConfig;
					
				} else {
					
					config.windows[0] = windowConfig;
					
				}
				
				for (i in 0...config.windows.length) {
					
					if (i < defaultConfig.windows.length) {
						
						__copyMissingFields (config.windows[i], defaultConfig.windows[i]);
						
					}
					
					__copyMissingFields (config.windows[i].parameters, defaultConfig.windows[i].parameters);
					
					if (Std.is (windowConfig.background, String)) {
						
						var background = StringTools.replace (Std.string (windowConfig.background), "#", "");
						
						if (background.indexOf ("0x") > -1) {
							
							windowConfig.background = Std.parseInt (background);
							
						} else {
							
							windowConfig.background = Std.parseInt ("0x" + background);
							
						}
						
					}
					
				}
				
			}
			
			if (Reflect.field (config.windows[0], "rootPath")) {
				
				config.rootPath = Reflect.field (config.windows[0], "rootPath");
				Reflect.deleteField (config.windows[0], "rootPath");
				
			}
			
			config.windows[0].element = htmlElement;
			config.windows[0].width = width;
			config.windows[0].height = height;
			
			__applicationEntryPoint[projectName] (config);
			
		}
		
	}
	#end
	
	
	public static function exit (code:Int):Void {
		
		#if ((sys || air) && !macro)
		if (Application.current != null) {
			
			Application.current.onExit.dispatch (code);
			
			if (Application.current.onExit.canceled) {
				
				return;
				
			}
			
		}
		#end
		
		#if sys
		Sys.exit (code);
		#elseif air
		NativeApplication.nativeApplication.exit (code);
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
			
			#if ios
			var tablet = NativeCFFI.lime_system_get_ios_tablet ();
			var scale = Application.current.window.scale;
			if (!tablet && scale > 2.46) {
				display.dpi = 401; // workaround for iPhone Plus
			} else {
				display.dpi = (tablet ? 132 : 163) * scale;
			}
			#elseif android
			var getDisplayDPI = JNI.createStaticMethod ("org/haxe/lime/GameActivity", "getDisplayDPI", "()D");
			display.dpi = Math.round (getDisplayDPI ());
			#else
			display.dpi = displayInfo.dpi;
			#end
			
			display.supportedModes = [];
			
			var displayMode;
			
			for (mode in cast (displayInfo.supportedModes, Array<Dynamic>)) {
				
				displayMode = new DisplayMode (mode.width, mode.height, mode.refreshRate, mode.pixelFormat);
				display.supportedModes.push (displayMode);
				
			}
			
			var mode = displayInfo.currentMode;
			var currentMode = new DisplayMode (mode.width, mode.height, mode.refreshRate, mode.pixelFormat);
			
			for (mode in display.supportedModes) {
				
				if (currentMode.pixelFormat == mode.pixelFormat && currentMode.width == mode.width && currentMode.height == mode.height && currentMode.refreshRate == mode.refreshRate) {
					
					currentMode = mode;
					break;
					
				}
				
			}
			
			display.currentMode = currentMode;
			
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
			//var div = Browser.document.createElement ("div");
			//div.style.width = "1in";
			//Browser.document.body.appendChild (div);
			//var ppi = Browser.document.defaultView.getComputedStyle (div, null).getPropertyValue ("width");
			//Browser.document.body.removeChild (div);
			//display.dpi = Std.parseFloat (ppi);
			display.dpi = 96 * Browser.window.devicePixelRatio;
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
		#elseif (js && !nodejs)
		return Std.int (Browser.window.performance.now ());
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
			
			#if (sys && windows)
			
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
	
	
	@:noCompletion private static function __copyMissingFields (target:Dynamic, source:Dynamic):Void {
		
		if (source == null || target == null) return;
		
		for (field in Reflect.fields (source)) {
			
			if (!Reflect.hasField (target, field)) {
				
				Reflect.setField (target, field, Reflect.field (source, field));
				
			}
			
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
	
	
	private static function __registerEntryPoint (projectName:String, entryPoint:Function, config:Config):Void {
		
		if (__applicationConfig == null) {
			
			__applicationConfig = new Map ();
			
		}
		
		if (__applicationEntryPoint == null) {
			
			__applicationEntryPoint = new Map ();
			
		}
		
		__applicationEntryPoint[projectName] = entryPoint;
		__applicationConfig[projectName] = config;
		
	}
	
	
	private static function __runProcess (command:String, args:Array<String> = null):String {
		
		#if sys
		try {
			
			if (args == null) args = [];
			
			var process = new Process (command, args);
			var value = StringTools.trim (process.stdout.readLine ().toString ());
			process.close ();
			return value;
			
		} catch (e:Dynamic) {}
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
		
		if (endianness == null) {
			
			#if (ps3 || wiiu || flash)
			return BIG_ENDIAN;
			#else
			var arrayBuffer = new ArrayBuffer (2);
			var uint8Array = new UInt8Array (arrayBuffer);
			var uint16array = new UInt16Array (arrayBuffer);
			uint8Array[0] = 0xAA;
			uint8Array[1] = 0xBB;
			if (uint16array[0] == 0xAABB) endianness = BIG_ENDIAN;
			else endianness = LITTLE_ENDIAN;
			#end
			
		}
		
		return endianness;
		
	}
	
	
	private static function get_manufacturer ():String {
		
		#if windows
		return NativeCFFI.lime_system_get_manufacturer ();
		#elseif android
		var manufacturer:String = JNI.createStaticField ("android/os/Build", "MANUFACTURER", "Ljava/lang/String;").get ();
		if (manufacturer != null) {
			return manufacturer.charAt (0).toUpperCase () + manufacturer.substr (1);
		}
		#elseif (ios || mac)
		return "Apple";
		#elseif linux
		return __runProcess ("cat", [ "/sys/devices/virtual/dmi/id/product_name" ]);
		#end
		return null;
		
	}
	
	
	private static function get_model ():String {
		
		#if (windows || ios)
		return NativeCFFI.lime_system_get_model ();
		#elseif android
		var manufacturer:String = JNI.createStaticField ("android/os/Build", "MANUFACTURER", "Ljava/lang/String;").get ();
		var model:String = JNI.createStaticField ("android/os/Build", "MODEL", "Ljava/lang/String;").get ();
		if (manufacturer != null && model != null) {
			if (StringTools.startsWith (model.toLowerCase (), manufacturer.toLowerCase ())) {
				model = StringTools.trim (model.substr (manufacturer.length));
				while (StringTools.startsWith (model, "-")) {
					model = StringTools.trim (model.substr (1));
				}
			}
			return model;
		}
		#elseif mac
		return __runProcess ("sysctl", [ "-n", "hw.model" ]);
		#elseif linux
		return __runProcess ("cat", [ "/sys/devices/virtual/dmi/id/sys_vendor" ]);
		#end
		return null;
		
	}
	
	
	private static function get_version ():String {
		
		#if windows
		var version:String = NativeCFFI.lime_system_get_version ();
		if (version != null) return StringTools.trim (version);
		#elseif android
		var release = JNI.createStaticField ("android/os/Build$VERSION", "RELEASE", "Ljava/lang/String;").get ();
		var api = JNI.createStaticField ("android/os/Build$VERSION", "SDK_INT", "I").get ();
		if (release != null && api != null) return "Android " + release + " (API " + api + ")";
		#elseif ios
		var name = "iOS";
		var version:String = NativeCFFI.lime_system_get_version ();
		if (name != null && version != null) return name + " " + version;
		#elseif mac
		//var name = __runProcess ("sw_vers", [ "-productName" ]);
		var name = "macOS";
		var version = __runProcess ("sw_vers", [ "-productVersion" ]);
		if (name != null && version != null) return name + " " + version;
		#elseif linux
		return __runProcess ("lsb_release", [ "-ds" ]);
		#end
		return null;
		
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