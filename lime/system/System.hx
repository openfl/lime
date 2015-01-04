package lime.system;
#if !macro


#if (js && html5)
import js.html.HtmlElement;
import js.Browser;
#end

#if (sys && !html5)
import sys.io.Process;
#end


class System {
	
	
	public static var disableCFFI:Bool;
	
	
	@:noCompletion private static var __moduleNames:Map<String, String> = null;
	
	#if neko
	private static var __loadedNekoAPI:Bool;
	#elseif nodejs
	private static var __nodeNDLLModule:Dynamic;
	#end
	
	
	#if (js && html5)
	@:keep @:expose("lime.embed")
	public static function embed (elementName:String, width:Null<Int> = null, height:Null<Int> = null, background:String = null) {
		
		var element:HtmlElement = null;
		
		if (elementName != null) {
			
			element = cast Browser.document.getElementById (elementName);
			
		} else {
			
			element = cast Browser.document.createElement ("div");
			
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
		ApplicationMain.config.element = element;
		ApplicationMain.config.width = width;
		ApplicationMain.config.height = height;
		ApplicationMain.create ();
		#end
		
	}
	#end
	
	
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
	
	
	public static function load (library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic {
		
		#if disable_cffi
		var disableCFFI = true;
		#end
		
		if (disableCFFI) {
			
			return Reflect.makeVarArgs (function (__) return {});
			
		}
		
		if (lazy) {
			
			#if neko
			return neko.Lib.loadLazy (library, method, args);
			#elseif cpp
			return cpp.Lib.loadLazy (library, method, args);
			#end
			
		}
		
		#if !disable_cffi
		#if (sys && !html5)
		
		#if (iphone || emscripten || android || static_link)
		return cpp.Lib.load (library, method, args);
		#end
		
		if (__moduleNames == null) __moduleNames = new Map<String, String> ();
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
			
			__nodeNDLLModule = untyped require('bindings')('node_ndll');
			
		}
		#end
		
		__moduleNames.set (library, library);
		
		var result:Dynamic = tryLoad ("./" + library, library, method, args);
		
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
		
		#if neko
		if (library == "lime") {
			
			loadNekoAPI ();
			
		}
		#end
		
		#else
		
		var result = null;
		
		#end
		#else
		
		var result = function (_, _, _, _, _, _) { return { }; };
		
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
		
		#if (sys && !html5 || nodejs)
		
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
	
	private static function loadNekoAPI ():Void {
		
		if (!__loadedNekoAPI) {
			
			var init = load ("lime", "neko_init", 5);
			
			if (init != null) {
				
				loaderTrace ("Found nekoapi @ " + __moduleNames.get ("lime"));
				init (function(s) return new String (s), function (len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
				
			} else {
				
				throw ("Could not find NekoAPI interface.");
				
			}
			
			__loadedNekoAPI = true;
			
		}
		
	}
	
	#end
	
	
}


#else


import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;


class System {
	
	
	public static function includeTools () {
		
		var paths = Context.getClassPath ();
		
		for (path in paths) {
			
			if (FileSystem.exists (path + "/tools/CommandLineTools.hx")) {
				
				Compiler.addClassPath (path + "/tools");
				
			}
			
		}
		
	}
	
	
}


#end