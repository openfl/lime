package lime.system;


#if !macro
import lime.app.Application;
#end

#if flash
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


class System {
	
	
	public static var applicationDirectory (get, null):String;
	public static var applicationStorageDirectory (get, null):String;
	public static var desktopDirectory (get, null):String;
	public static var disableCFFI:Bool;
	public static var documentsDirectory (get, null):String;
	public static var fontsDirectory (get, null):String;
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
		ApplicationMain.config.background = color;
		ApplicationMain.config.element = htmlElement;
		ApplicationMain.config.width = width;
		ApplicationMain.config.height = height;
		ApplicationMain.config.assetsPrefix = assetsPrefix;
		ApplicationMain.create ();
		#end
		
	}
	#end
	
	
	public static function exit (code:Int):Void {
		
		#if sys
		// TODO: Clean shutdown?
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
	
	
	public static function getTimer ():Int {
		
		#if flash
		return flash.Lib.getTimer ();
		#elseif js
		return Std.int (Date.now ().getTime ());
		#elseif !disable_cffi
		return lime_system_get_timer ();
		#elseif cpp
		return Std.int (untyped __global__.__time_stamp () * 1000);
		#elseif sys
		return Std.int (Sys.time () * 1000);
		#else
		return 0;
		#end
		
	}
	
	
	public static function load (library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic {
		
		#if (disable_cffi || macro)
		var disableCFFI = true;
		#end
		
		#if optional_cffi
		lazy = true;
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
			
			var init = load ("lime", "neko_init", 5, lazy);
			
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
			
			__loadedNekoAPI = true;
			
		}
		
	}
	
	#end
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_applicationDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory (SystemDirectory.APPLICATION, null, null);
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
		return lime_system_get_directory (SystemDirectory.APPLICATION_STORAGE, company, file);
		#else
		return null;
		#end
		
	}
	
	
	private static function get_desktopDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory (SystemDirectory.DESKTOP, null, null);
		#else
		return null;
		#end
		
	}
	
	
	private static function get_documentsDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory (SystemDirectory.DOCUMENTS, null, null);
		#else
		return null;
		#end
		
	}
	
	
	private static function get_fontsDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory (SystemDirectory.FONTS, null, null);
		#else
		return null;
		#end
		
	}
	
	
	private static function get_userDirectory ():String {
		
		#if (cpp || neko || nodejs)
		return lime_system_get_directory (SystemDirectory.USER, null, null);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_system_get_directory = System.load ("lime", "lime_system_get_directory", 3);
	private static var lime_system_get_timer = System.load ("lime", "lime_system_get_timer", 0);
	#end
	
	
}


@:enum private abstract SystemDirectory(Int) from Int to Int {
	
	var APPLICATION = 0;
	var APPLICATION_STORAGE = 1;
	var DESKTOP = 2;
	var DOCUMENTS = 3;
	var FONTS = 4;
	var USER = 5;
	
}