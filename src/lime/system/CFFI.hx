package lime.system;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.macros.CFFIMacro;
#if (sys && !macro)
import sys.io.Process;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class CFFI
{
	@:noCompletion private static var __moduleNames:Map<String, String> = null;
	#if neko
	private static var __loadedNekoAPI:Bool;
	#elseif nodejs
	private static var __nodeNDLLModule:Dynamic;
	#end
	public static var available:Bool;
	public static var enabled:Bool;

	private static function __init__():Void
	{
		#if lime_cffi
		available = true;
		enabled = #if disable_cffi false; #else true; #end
		#else
		available = false;
		enabled = false;
		#end
	}

	#if macro
	public static function build(defaultLibrary:String = "lime")
	{
		return CFFIMacro.build(defaultLibrary);
	}
	#end

	/**
	 * Tries to load a native CFFI primitive on compatible platforms
	 * @param	library	The name of the native library (such as "lime")
	 * @param	method	The exported primitive method name
	 * @param	args	The number of arguments
	 * @param	lazy	Whether to load the symbol immediately, or to allow lazy loading
	 * @return	The loaded method
	 */
	public static function load(library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic
	{
		#if (disable_cffi || macro || hl)
		var enabled = false;
		#end

		#if optional_cffi
		if (library != "lime" || method != "neko_init")
		{
			lazy = true;
		}
		#end

		if (!enabled)
		{
			return Reflect.makeVarArgs(function(__) return {});
		}

		var result:Dynamic = null;

		#if (!disable_cffi && !macro)
		#if (sys && !html5)
		if (__moduleNames == null) __moduleNames = new Map<String, String>();

		if (lazy)
		{
			__moduleNames.set(library, library);

			try
			{
				#if neko
				result = neko.Lib.loadLazy(library, method, args);
				#elseif java
				result = __loadJava(library, method, args);
				#elseif cpp
				result = cpp.Lib.loadLazy(library, method, args);
				#end
			}
			catch (e:Dynamic) {}
		}
		else
		{
			#if (cpp && (iphone || emscripten || android || static_link || tvos))
			return cpp.Lib.load(library, method, args);
			#end

			if (__moduleNames.exists(library))
			{
				#if cpp
				return cpp.Lib.load(__moduleNames.get(library), method, args);
				#elseif neko
				#if neko_cffi_trace
				var result:Dynamic = neko.Lib.load(__moduleNames.get(library), method, args);
				if (result == null) return null;

				return Reflect.makeVarArgs(function(args)
				{
					trace("Called " + library + "@" + method);
					return Reflect.callMethod(result, result, args);
				});
				#else
				return neko.Lib.load(__moduleNames.get(library), method, args);
				#end
				#elseif nodejs
				return untyped __nodeNDLLModule.load_lib(__moduleNames.get(library), method, args);
				#elseif java
				result = __loadJava(__moduleNames.get(library), method, args);
				#elseif cs
				return untyped CSFunctionLoader.load(__moduleNames.get(library), method, args);
				#else
				return null;
				#end
			}

			#if waxe
			if (library == "lime")
			{
				flash.Lib.load("waxe", "wx_boot", 1);
			}
			#elseif nodejs
			if (__nodeNDLLModule == null)
			{
				__nodeNDLLModule = untyped require('ndll');
			}
			#end

			__moduleNames.set(library, library);

			result = __tryLoad("./" + library, library, method, args);

			if (result == null)
			{
				result = __tryLoad(".\\" + library, library, method, args);
			}

			if (result == null)
			{
				result = __tryLoad(library, library, method, args);
			}

			if (result == null)
			{
				var haxelib = __findHaxelib("lime");

				if (haxelib != "")
				{
					result = __tryLoad(haxelib + "/ndll/" + __sysName() + "/" + library, library, method, args);

					if (result == null)
					{
						result = __tryLoad(haxelib + "/ndll/" + __sysName() + "64/" + library, library, method, args);
					}
				}
			}

			__loaderTrace("Result : " + result);
		}

		#if neko
		if (library == "lime" && method != "neko_init")
		{
			__loadNekoAPI(lazy);
		}
		#end
		#end
		#else
		result = function(_, _, _, _, _, _)
		{
			return {};
		};
		#end

		return result;
	}

	public static macro function loadPrime(library:String, method:String, signature:String, lazy:Bool = false):Dynamic
	{
		#if (!display && !macro && cpp && !disable_cffi)
		return cpp.Prime.load(library, method, signature, lazy);
		#else
		var args = signature.length - 1;

		if (args > 5)
		{
			args = -1;
		}

		return {call: CFFI.load(library, method, args, lazy)};
		#end
	}

	private static function __findHaxelib(library:String):String
	{
		#if (sys && !macro && !html5)
		try
		{
			var proc = new Process("haxelib", ["path", library]);

			if (proc != null)
			{
				var stream = proc.stdout;

				try
				{
					while (true)
					{
						var s = stream.readLine();

						if (s.substr(0, 1) != "-")
						{
							stream.close();
							proc.close();
							__loaderTrace("Found haxelib " + s);
							return s;
						}
					}
				}
				catch (e:Dynamic) {}

				stream.close();
				proc.close();
			}
		}
		catch (e:Dynamic) {}
		#end

		return "";
	}

	private static function __loaderTrace(message:String)
	{
		#if (sys && !html5)
		// #if (haxe_ver < 3.4)
		// var get_env = cpp.Lib.load ("std", "get_env", 1);
		// var debug = (get_env ("OPENFL_LOAD_DEBUG") != null);
		// #else
		var debug = (Sys.getEnv("OPENFL_LOAD_DEBUG") != null);
		// #end

		if (debug)
		{
			Sys.println(message);
		}
		#end
	}

	#if java
	private static var __loadedLibraries = new Map<String, Bool>();

	private static function __loadJava(library:String, method:String, args:Int = 0)
	{
		if (!__loadedLibraries.exists(library))
		{
			var extension = #if android ".so" #else ".ndll" #end;
			var path = Sys.getCwd() + "/" + library + extension;

			java.lang.System.load(path);

			__loadedLibraries.set(library, true);

			trace("load library: " + library);
		}

		return null;
	}
	#end

	#if neko
	private static function __loadNekoAPI(lazy:Bool):Void
	{
		if (!__loadedNekoAPI)
		{
			var init:Dynamic = null;
			try
			{
				init = load("lime", "neko_init", 5);
			}
			catch (e:Dynamic)
			{
			}

			if (init != null)
			{
				__loaderTrace("Found nekoapi @ " + __moduleNames.get("lime"));
				init(function(s) return new String(s), function(len:Int)
				{
					var r = [];
					if (len > 0) r[len - 1] = null;
					return r;
				}, null, true, false);

				__loadedNekoAPI = true;
			}
			else if (!lazy)
			{
				var ndllFolder = __findHaxelib("lime") + "/ndll/" + __sysName();
				throw "Could not find lime.ndll. This file is provided with Lime's Haxelib releases, but not via Git. "
					+ "Please copy it from Lime's latest Haxelib release into either "
					+ ndllFolder + " or " + ndllFolder + "64, as appropriate for your system. "
					+ "Advanced users may run `lime rebuild cpp` instead.";
			}
		}
	}
	#end

	private static function __sysName():String
	{
		#if (sys && !html5)
		#if cpp
		var sys_string = cpp.Lib.load("std", "sys_string", 0);
		return sys_string();
		#else
		return Sys.systemName();
		#end
		#else
		return null;
		#end
	}

	private static function __tryLoad(name:String, library:String, func:String, args:Int):Dynamic
	{
		#if sys
		try
		{
			#if cpp
			var result = cpp.Lib.load(name, func, args);
			#elseif (neko)
			var result = neko.Lib.load(name, func, args);
			#elseif nodejs
			var result = untyped __nodeNDLLModule.load_lib(name, func, args);
			#elseif java
			var result = __loadJava(name, func, args);
			#elseif cs
			var result = CSFunctionLoader.load(name, func, args);
			#else
			var result = null;
			#end

			if (result != null)
			{
				__loaderTrace("Got result " + name);
				__moduleNames.set(library, name);
				return result;
			}
		}
		catch (e:Dynamic)
		{
			__loaderTrace("Failed to load : " + name);
		}
		#end

		return null;
	}
}

#if cs
@:dox(hide) private class CSFunctionLoader
{
	public static function load(name:String, func:String, args:Int):Dynamic
	{
		var func:cs.ndll.NDLLFunction = cs.ndll.NDLLFunction.Load(name, func, args);

		if (func == null)
		{
			return null;
		}

		if (args == -1)
		{
			var haxeFunc:Dynamic = function(args:Array<Dynamic>):Dynamic
			{
				return func.CallMult(args);
			}

			return Reflect.makeVarArgs(haxeFunc);
		}
		else if (args == 0)
		{
			return function():Dynamic
			{
				return func.Call0();
			}
		}
		else if (args == 1)
		{
			return function(arg1:Dynamic):Dynamic
			{
				return func.Call1(arg1);
			}
		}
		else if (args == 2)
		{
			return function(arg1:Dynamic, arg2:Dynamic):Dynamic
			{
				return func.Call2(arg1, arg2);
			}
		}
		else if (args == 3)
		{
			return function(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Dynamic
			{
				return func.Call3(arg1, arg2, arg3);
			}
		}
		else if (args == 4)
		{
			return function(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic):Dynamic
			{
				return func.Call4(arg1, arg2, arg3, arg4);
			}
		}
		else if (args == 5)
		{
			return function(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic, arg4:Dynamic, arg5:Dynamic):Dynamic
			{
				return func.Call5(arg1, arg2, arg3, arg4, arg5);
			}
		}

		return null;
	}
}
#end
#end
