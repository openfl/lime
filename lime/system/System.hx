package lime.system;


import lime.math.Rectangle;

#if !macro
import lime.app.Application;
#else
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import cpp.Prime;
#end

#if flash
import flash.system.Capabilities;
import flash.Lib;
#end

#if (js && html5)
#if (haxe_ver >= "3.2")
import js.html.Element;
#else
import js.html.HtmlElement;
#end
import js.Browser;
#end

#if (sys && !html5)
import sys.io.Process;
#end

@:access(lime.system.Display)
@:access(lime.system.DisplayMode)


class System {
	
	
	public static var applicationDirectory (get, null):String;
	public static var applicationStorageDirectory (get, null):String;
	public static var desktopDirectory (get, null):String;
	public static var disableCFFI:Bool;
	public static var documentsDirectory (get, null):String;
	public static var endianness (get, null):Endian;
	public static var fontsDirectory (get, null):String;
	public static var numDisplays (get, null):Int;
	public static var userDirectory (get, null):String;
	
	
	@:noCompletion private static var __moduleNames:Map<String, String> = null;
	
	#if neko
	private static var __loadedNekoAPI:Bool;
	#elseif nodejs
	private static var __nodeNDLLModule:Dynamic;
	#end
	
	
	#if (js && html5)
	@:keep @:expose("lime.embed")
	public static function embed (element:Dynamic, width:Null<Int> = null, height:Null<Int> = null, background:String = null, assetsPrefix:String = null) {
		
		var htmlElement:#if (haxe_ver >= "3.2") Element #else HtmlElement #end = null;
		
		if (Std.is (element, String)) {
			
			htmlElement = cast Browser.document.getElementById (cast (element, String));
			
		} else if (element == null) {
			
			htmlElement = cast Browser.document.createElement ("div");
			
		} else {
			
			htmlElement = cast element;
			
		}
		
		var color = null;
		
		if (background != null) {
			
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
		
		#if sys
		#if !macro
		if (Application.current != null) {
			
			// TODO: Clean exit?
			
			Application.current.onExit.dispatch (code);
			
		}
		#end
		Sys.exit (code);
		#end
		
	}
	
	
	static private function findHaxeLib (library:String):String {
		
		#if (sys && !html5)
			
			try {
				
				var proc = new Process ("haxelib", [ "path", library ]);
				
				if (proc != null) {
					
					var stream = proc.stdout;
					
					try {
						
						while (true) {
							
							var s = stream.readLine ();
							
							if (s.substr (0, 1) != "-") {
								
								stream.close ();
								proc.close ();
								loaderTrace ("Found haxelib " + s);
								return s;
								
							}
							
						}
						
					} catch(e:Dynamic) { }
					
					stream.close ();
					proc.close ();
					
				}
				
			} catch (e:Dynamic) { }
			
		#end
		
		return "";
		
	}
	
	
	public static function getDisplay (id:Int):Display {
		
		#if (cpp || neko || nodejs)
		var displayInfo:Dynamic = lime_system_get_display.call (id);
		
		if (displayInfo != null) {
			
			var display = new Display ();
			display.id = id;
			display.name = displayInfo.name;
			display.bounds = new Rectangle (displayInfo.bounds.x, displayInfo.bounds.y, displayInfo.bounds.width, displayInfo.bounds.height);
			display.supportedModes = [];
			
			var displayMode;
			
			for (mode in cast (displayInfo.supportedModes, Array<Dynamic>)) {
				
				displayMode = new DisplayMode (mode.width, mode.height, mode.refreshRate, mode.pixelFormat);
				display.supportedModes.push (displayMode);
				
			}
			
			display.currentMode = display.supportedModes[displayInfo.currentMode];
			return display;
			
		}
		#elseif (flash || html5)
		if (id == 0) {
			
			var display = new Display ();
			display.id = 0;
			display.name = "Generic Display";
			
			#if flash
			display.currentMode = new DisplayMode (Std.int (Capabilities.screenResolutionX), Std.int (Capabilities.screenResolutionY), 60, ARGB32);
			#else
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
		#elseif !disable_cffi
		return cast lime_system_get_timer.call ();
		#elseif cpp
		return Std.int (untyped __global__.__time_stamp () * 1000);
		#elseif sys
		return Std.int (Sys.time () * 1000);
		#else
		return 0;
		#end
		
	}
	
	
	/**
	 * Tries to load a native CFFI primitive on compatible platforms
	 * @param	library	The name of the native library (such as "lime")
	 * @param	method	The exported primitive method name
	 * @param	args	The number of arguments
	 * @param	lazy	Whether to load the symbol immediately, or to allow lazy loading
	 * @return	The loaded method
	 */
	public static function load (library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic {
		
		#if (disable_cffi || macro)
		var disableCFFI = true;
		#end
		
		#if optional_cffi
		if (library != "lime" || method != "neko_init") {
			
			lazy = true;
			
		}
		#end
		
		if (disableCFFI) {
			
			return Reflect.makeVarArgs (function (__) return {});
			
		}
		
		var result:Dynamic = null;
		
		#if (!disable_cffi && !macro)
		#if (sys && !html5)
		
		if (__moduleNames == null) __moduleNames = new Map<String, String> ();
		
		if (lazy) {
			
			__moduleNames.set (library, library);
			
			try {
				
				#if lime_legacy
				if (library == "lime") return null;
				#elseif !lime_hybrid
				if (library == "lime-legacy") return null;
				#end
				
				#if neko
				result = neko.Lib.loadLazy (library, method, args);
				#elseif cpp
				result = cpp.Lib.loadLazy (library, method, args);
				#end
				
			} catch (e:Dynamic) {}
			
		} else {
			
			#if (iphone || emscripten || android || static_link)
			return cpp.Lib.load (library, method, args);
			#end
			
			
			if (__moduleNames.exists (library)) {
				
				#if cpp
				return cpp.Lib.load (__moduleNames.get (library), method, args);
				#elseif neko
				return neko.Lib.load (__moduleNames.get (library), method, args);
				#elseif nodejs
				return untyped __nodeNDLLModule.load_lib (__moduleNames.get (library), method, args);
				#else
				return null;
				#end
				
			}
			
			#if waxe
			if (library == "lime") {
				
				flash.Lib.load ("waxe", "wx_boot", 1);
				
			}
			#elseif nodejs
			if (__nodeNDLLModule == null) {
				
				__nodeNDLLModule = untyped require('ndll');
				
			}
			#end
			
			__moduleNames.set (library, library);
			
			result = tryLoad ("./" + library, library, method, args);
			
			if (result == null) {
				
				result = tryLoad (".\\" + library, library, method, args);
				
			}
			
			if (result == null) {
				
				result = tryLoad (library, library, method, args);
				
			}
			
			if (result == null) {
				
				var slash = (sysName ().substr (7).toLowerCase () == "windows") ? "\\" : "/";
				var haxelib = findHaxeLib ("lime");
				
				if (haxelib != "") {
					
					result = tryLoad (haxelib + slash + "ndll" + slash + sysName () + slash + library, library, method, args);
					
					if (result == null) {
						
						result = tryLoad (haxelib + slash + "ndll" + slash + sysName() + "64" + slash + library, library, method, args);
						
					}
					
				}
				
			}
			
			loaderTrace ("Result : " + result);
			
		}
		
		#if neko
		if (library == "lime" && method != "neko_init") {
			
			loadNekoAPI (lazy);
			
		}
		#end
		
		#end
		#else
		
		result = function (_, _, _, _, _, _) { return { }; };
		
		#end
		
		return result;
		
	}
	
	
	#if macro
	private static function __codeToType (code:String, forCpp:Bool):String {
		
		switch (code) {
			
			case "b" : return "Bool";
			case "i" : return "Int";
			case "d" : return "Float";
			case "s" : return "String";
			case "f" : return forCpp ? "cpp.Float32" : "Float";
			case "o" : return forCpp ? "cpp.Object" : "Dynamic";
			case "v" : return forCpp ? "cpp.Void" : "Void";
			case "c" :
				if (forCpp)
					return "cpp.ConstCharStar";
				throw "const char * type only supported in cpp mode";
			default:
				throw "Unknown signature type :" + code;
			
		}
		
	}
	#end
	
	
	#if ((haxe_ver >= 3.2) && !debug_cffi)
	public static inline macro function loadPrime (library:String, method:String, signature:Expr, lazy:Bool = false) {
		
		var signatureString = "";
		var signatureType = Context.typeExpr (signature);
		
		switch (signatureType.t) {
			
			case TFun (args, result):
				
				for (arg in args) {
					
					switch (TypeTools.toString (arg.t)) {
						
						case "Int", "Int16", "Int32": signatureString += "i";
						case "Bool": signatureString += "b";
						case "Float32": signatureString += "f";
						case "Float", "Float64": signatureString += "d";
						case "String": signatureString += "s";
						case "ConstCharStar": signatureString += "c";
						case "Void": if (signatureString.length > 0) signatureString += "v";
						default: signatureString += "o";
						
					}
					
				}
				
				switch (TypeTools.toString (result)) {
					
					case "Int", "Int16", "Int32": signatureString += "i";
					case "Bool": signatureString += "b";
					case "Float32": signatureString += "f";
					case "Float", "Float64": signatureString += "d";
					case "String": signatureString += "s";
					case "ConstCharStar": signatureString += "c";
					case "Void": signatureString += "v";
					default: signatureString += "o";
					
				}
			
			case TInst (_.get () => { pack: [], name: "String" }, _):
				
				signatureString = ExprTools.getValue (signature);
				
			case TAbstract (_.get () => { pack: [], name: "Int" }, _):
				
				var typeString = "Dynamic";
				var args:Int = ExprTools.getValue (signature);
				
				for (i in 0...args) {
					
					typeString += "->Dynamic";
					
				}
				
				return Context.parse ('new cpp.Callable<$typeString> (System.load ("$library", "$method", $args, $lazy))', Context.currentPos ());
			
			default:
			
		}
		
		if (signatureString == null || signatureString == "") {
			
			throw "Invalid function signature";
			
		}
		
		var parts = signatureString.split ("");
		
		var cppMode = Context.defined ("cpp");
		var typeString, expr;
		
		if (parts.length == 1) {
			
			typeString = "Void";
			
		} else {
			
			typeString = __codeToType (parts.shift (), cppMode);
			
		}
		
		for (part in parts) {
			
			typeString += "->" + __codeToType (part, cppMode);
			
		}
		
		if (cppMode) {
			
			typeString = "cpp.Callable<" + typeString + ">";
			expr = 'new $typeString (cpp.Prime._loadPrime ("$library", "$method", "$signatureString", $lazy))';
			
		} else {
			
			var args = signatureString.length - 1;
			
			if (args > 5) {
				
				args = -1;
				
			}
			
			expr = 'new cpp.Callable<$typeString> (System.load ("$library", "$method", $args, $lazy))';
			
		}
		
		return Context.parse (expr, Context.currentPos ());
		
	}
	#else
	public static function loadPrime (library:String, method:String, signature:String):Dynamic {
		
		var args = signature.length - 1;
		
		if (args > 5) {
			
			args = -1;
			
		}
		
		// TODO: Need a macro function for debug to work on C++
		
		#if (!debug_cffi || cpp)
		
		return { call: System.load (library, method, args) };
		
		#else
		
		var handle = System.load (library, method, args);
		return { call: Reflect.makeVarArgs (function (args) {
			
			#if neko
			Sys.println ('$library@$method');
			#if debug_cffi_args
			Sys.println (args);
			#end
			#else
			trace ('$library@$method');
			#if debug_cffi_args
			trace (args);
			#end
			#end
			
			return Reflect.callMethod (handle, handle, args);
			
		}) };
		
		#end
		
	}
	#end
	
	
	private static function sysName ():String {
		
		#if (sys && !html5)
			
			#if cpp
				
				var sys_string = cpp.Lib.load ("std", "sys_string", 0);
				return sys_string ();
				
			#else
				
				return Sys.systemName ();
				
			#end
			
		#else
			
			return null;
			
		#end
		
	}
	
	
	private static function tryLoad (name:String, library:String, func:String, args:Int):Dynamic {
		
		#if sys
		
		try {
			
			#if cpp
			var result = cpp.Lib.load (name, func, args);
			#elseif (neko)
			var result = neko.Lib.load (name, func, args);
			#elseif nodejs
			var result = untyped __nodeNDLLModule.load_lib (name, func, args);
			#else
			var result = null;
			#end
			
			if (result != null) {
				
				loaderTrace ("Got result " + name);
				__moduleNames.set (library, name);
				return result;
				
			}
			
		} catch (e:Dynamic) {
			
			loaderTrace ("Failed to load : " + name);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	private static function loaderTrace (message:String) {
		
		#if (sys && !html5)
		
		#if cpp
			
			var get_env = cpp.Lib.load ("std", "get_env", 1);
			var debug = (get_env ("OPENFL_LOAD_DEBUG") != null);
			
		#else
			
			var debug = (Sys.getEnv ("OPENFL_LOAD_DEBUG") !=null);
			
		#end
		
		if (debug) {
			
			Sys.println (message);
			
		}
		
		#end
		
	}
	
	
	#if neko
	
	private static function loadNekoAPI (lazy:Bool):Void {
		
		if (!__loadedNekoAPI) {
			
			try {
				
				var init = load ("lime", "neko_init", 5);
				
				if (init != null) {
					
					loaderTrace ("Found nekoapi @ " + __moduleNames.get ("lime"));
					init (function(s) return new String (s), function (len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
					
				} else if (!lazy) {
					
					throw ("Could not find NekoAPI interface.");
					
				}
				
				#if lime_hybrid
				var init = load ("lime-legacy", "neko_init", 5);
				
				if (init != null) {
					
					loaderTrace ("Found nekoapi @ " + __moduleNames.get ("lime-legacy"));
					init (function(s) return new String (s), function (len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
					
				} else if (!lazy) {
					
					throw ("Could not find NekoAPI interface.");
					
				}
				#end
				
			} catch (e:Dynamic) {
				
				if (!lazy) {
					
					throw ("Could not find NekoAPI interface.");
					
				}
				
			}
			
			__loadedNekoAPI = true;
			
		}
		
	}
	
	#end
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_applicationDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.APPLICATION, null, null);
		#elseif flash
		if (Capabilities.playerType == "Desktop") {
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), "applicationDirectory").nativePath;
			
		} else {
			
			return null;
			
		}
		#else
		return null;
		#end
		
	}
	
	
	private static function get_applicationStorageDirectory ():String {
		
		var company = "MyCompany";
		var file = "MyApplication";
		
		#if !macro
		if (Application.current != null && Application.current.config != null) {
			
			if (Application.current.config.company != null) {
				
				company = Application.current.config.company;
				
			}
			
			if (Application.current.config.file != null) {
				
				file = Application.current.config.file;
				
			}
			
		}
		#end
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.APPLICATION_STORAGE, company, file);
		#elseif flash
		if (Capabilities.playerType == "Desktop") {
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), "applicationStorageDirectory").nativePath;
			
		} else {
			
			return null;
			
		}
		#else
		return null;
		#end
		
	}
	
	
	private static function get_desktopDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.DESKTOP, null, null);
		#elseif flash
		if (Capabilities.playerType == "Desktop") {
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), "desktopDirectory").nativePath;
			
		} else {
			
			return null;
			
		}
		#else
		return null;
		#end
		
	}
	
	
	private static function get_documentsDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.DOCUMENTS, null, null);
		#elseif flash
		if (Capabilities.playerType == "Desktop") {
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), "documentsDirectory").nativePath;
			
		} else {
			
			return null;
			
		}
		#else
		return null;
		#end
		
	}
	
	
	private static function get_fontsDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.FONTS, null, null);
		#else
		return null;
		#end
		
	}
	
	
	private static function get_numDisplays ():Int {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_num_displays.call ();
		#else
		return 1;
		#end
		
	}
	
	
	private static function get_userDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory.call (SystemDirectory.USER, null, null);
		#elseif flash
		if (Capabilities.playerType == "Desktop") {
			
			return Reflect.getProperty (Type.resolveClass ("flash.filesystem.File"), "userDirectory").nativePath;
			
		} else {
			
			return null;
			
		}
		#else
		return null;
		#end
		
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
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	private static var lime_system_get_directory = System.loadPrime ("lime", "lime_system_get_directory", "isss");
	private static var lime_system_get_display = System.loadPrime ("lime", "lime_system_get_display", "io");
	private static var lime_system_get_num_displays = System.loadPrime ("lime", "lime_system_get_num_displays", "i");
	private static var lime_system_get_timer = System.loadPrime ("lime", "lime_system_get_timer", "d");
	#else
	private static var lime_system_get_directory:Dynamic;
	private static var lime_system_get_display:Dynamic;
	private static var lime_system_get_num_displays:Dynamic;
	private static var lime_system_get_timer:Dynamic;
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