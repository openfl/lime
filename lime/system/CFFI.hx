package lime.system; #if !macro


#if sys
import sys.io.Process;
#end


class CFFI {
	
	
	@:noCompletion private static var __moduleNames:Map<String, String> = null;
	
	#if neko
	private static var __loadedNekoAPI:Bool;
	#elseif nodejs
	private static var __nodeNDLLModule:Dynamic;
	#end
	
	public static var available:Bool;
	public static var enabled:Bool;
	
	
	private static function __init__ ():Void {
		
		#if (cpp || neko || nodejs)
		available = true;
		enabled = #if disable_cffi false; #else true; #end
		#else
		available = false;
		enabled = false;
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
		var enabled = false;
		#end
		
		#if optional_cffi
		if (library != "lime" || method != "neko_init") {
			
			lazy = true;
			
		}
		#end
		
		if (!enabled) {
			
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
			
			result = __tryLoad ("./" + library, library, method, args);
			
			if (result == null) {
				
				result = __tryLoad (".\\" + library, library, method, args);
				
			}
			
			if (result == null) {
				
				result = __tryLoad (library, library, method, args);
				
			}
			
			if (result == null) {
				
				var slash = (__sysName ().substr (7).toLowerCase () == "windows") ? "\\" : "/";
				var haxelib = __findHaxelib ("lime");
				
				if (haxelib != "") {
					
					result = __tryLoad (haxelib + slash + "ndll" + slash + __sysName () + slash + library, library, method, args);
					
					if (result == null) {
						
						result = __tryLoad (haxelib + slash + "ndll" + slash + __sysName() + "64" + slash + library, library, method, args);
						
					}
					
				}
				
			}
			
			__loaderTrace ("Result : " + result);
			
		}
		
		#if neko
		if (library == "lime" && method != "neko_init") {
			
			__loadNekoAPI (lazy);
			
		}
		#end
		
		#end
		#else
		
		result = function (_, _, _, _, _, _) { return { }; };
		
		#end
		
		return result;
		
	}
	
	
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
				
				return Context.parse ('new cpp.Callable<$typeString> (lime.system.CFFI.load ("$library", "$method", $args, $lazy))', Context.currentPos ());
			
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
			
			expr = 'new cpp.Callable<$typeString> (lime.system.CFFI.load ("$library", "$method", $args, $lazy))';
			
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
		
		return { call: CFFI.load (library, method, args) };
		
		#else
		
		var handle = CFFI.load (library, method, args);
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
	
	
	private static function __findHaxelib (library:String):String {
		
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
								__loaderTrace ("Found haxelib " + s);
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
	
	
	private static function __loaderTrace (message:String) {
		
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
	private static function __loadNekoAPI (lazy:Bool):Void {
		
		if (!__loadedNekoAPI) {
			
			try {
				
				var init = load ("lime", "neko_init", 5);
				
				if (init != null) {
					
					__loaderTrace ("Found nekoapi @ " + __moduleNames.get ("lime"));
					init (function(s) return new String (s), function (len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
					
				} else if (!lazy) {
					
					throw ("Could not find NekoAPI interface.");
					
				}
				
				#if lime_hybrid
				var init = load ("lime-legacy", "neko_init", 5);
				
				if (init != null) {
					
					__loaderTrace ("Found nekoapi @ " + __moduleNames.get ("lime-legacy"));
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
	
	
	private static function __sysName ():String {
		
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
	
	
	private static function __tryLoad (name:String, library:String, func:String, args:Int):Dynamic {
		
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
				
				__loaderTrace ("Got result " + name);
				__moduleNames.set (library, name);
				return result;
				
			}
			
		} catch (e:Dynamic) {
			
			__loaderTrace ("Failed to load : " + name);
			
		}
		
		#end
		
		return null;
		
	}
	
	
}


#else


import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.Tools;
using haxe.macro.TypeTools;


class CFFI {
	
	
	public static function build (defaultLibrary:String = "lime"):Array<Field> {
		
		var pos = Context.currentPos ();
		var fields = Context.getBuildFields ();
		var newFields = [];
		
		for (field in fields) {
			
			switch (field) {
				
				case _ => { kind: FFun (fun), meta: meta } :
					
					for (m in meta) {
						
						if (m.name == ":cffi") {
							
							var library = null;
							var method = null;
							var lazy = false;
							
							if (Reflect.hasField (m, "params")) {
								
								if (m.params.length > 0) library = m.params[0].getValue ();
								if (m.params.length > 1) method = m.params[1].getValue ();
								if (m.params.length > 2) lazy = m.params[2].getValue ();
								
							}
							
							if (library == null || library == "") {
								
								library = defaultLibrary;
								
							}
							
							if (method == null || method == "") {
								
								method = field.name;
								
							}
							
							var typeArgs = [];
							
							for (arg in fun.args) {
								
								typeArgs.push ( { name: arg.name, opt: false, t: arg.type.toType () } );
								
							}
							
							var type = __getFunctionType (typeArgs, fun.ret.toType ());
							
							var typeString = type.string;
							var typeSignature = type.signature;
							var cffiExpr;
							
							if (Context.defined ("cpp")) {
								
								cffiExpr = 'new cpp.Callable<$typeString> (cpp.Prime._loadPrime ("$library", "$method", "$typeSignature", $lazy))';
								
							} else {
								
								var args = typeSignature.length - 1;
								
								if (args > 5) {
									
									args = -1;
									
								}
								
								cffiExpr = 'new cpp.Callable<$typeString> (lime.system.CFFI.load ("$library", "$method", $args, $lazy))';
								
							}
							
							var cffiName = "cffi_" + field.name;
							var cffiType = TPath ( { pack: [ "cpp" ], name: "Callable", params: [ TPType (TFun (type.args, type.result).toComplexType ()) ] } );
							
							newFields.push ( { name: cffiName, access: [ APrivate, AStatic ], kind: FieldType.FVar (cffiType, Context.parse (cffiExpr, pos)), pos: pos } );
							
							var newExpr = "";
							
							if (type.result.toString () != "Void" && type.result.toString () != "cpp.Void") {
								
								newExpr = "return ";
								
							}
							
							newExpr += '$cffiName.call (';
							
							for (i in 0...type.args.length) {
								
								if (i > 0) newExpr += ", ";
								newExpr += type.args[i].name;
								
							}
							
							newExpr += ")";
							
							field.access.push (AInline);
							fun.expr = Context.parse (newExpr, pos);
							
						}
						
					}
				
				default:
				
			}
			
		}
		
		fields = fields.concat (newFields);
		return fields;
		
	}
	
	
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
	
	
	private static function __getFunctionType (args:Array<{ name : String, opt : Bool, t : Type }>, result:Type) {
		
		var isCPP = Context.defined ("cpp");
		
		var typeArgs = [];
		var typeResult = null;
		var typeSignature = "";
		
		for (arg in args) {
			
			switch (arg.t.toString ()) {
				
				case "Int", "cpp.Int16", "cpp.Int32":
					
					typeArgs.push (arg);
					typeSignature += "i";
				
				case "Bool":
					
					typeArgs.push (arg);
					typeSignature += "b";
				
				case "cpp.Float32":
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Float32).toType () } );
						
					} else {
						
						typeArgs.push (arg);
						
					}
					
					typeSignature += "f";
				
				case "Float", "cpp.Float64":
					
					typeArgs.push (arg);
					typeSignature += "d";
				
				case "String":
					
					typeArgs.push (arg);
					typeSignature += "s";
				
				case "cpp.ConstCharStar":
					
					typeArgs.push (arg);
					typeSignature += "c";
				
				case "Void", "cpp.Void":
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Void).toType () } );
						
					} else {
						
						typeArgs.push (arg);
						
					}
					
					if (typeSignature.length > 0) {
						
						typeSignature += "v";
						
					}
					
				default:
					
					if (isCPP) {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :cpp.Object).toType () } );
						
					} else {
						
						typeArgs.push ( { name: arg.name, opt: false, t: (macro :Dynamic).toType () } );
						
					}
					
					typeSignature += "o";
				
			}
			
		}
		
		switch (result.toString ()) {
			
			case "Int", "cpp.Int16", "cpp.Int32":
				
				typeResult = result;
				typeSignature += "i";
			
			case "Bool":
				
				typeResult = result;
				typeSignature += "b";
			
			case "cpp.Float32":
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Float32).toType ();
					
				} else {
					
					typeResult = result;
					
				}
				
				typeSignature += "f";
			
			case "Float", "cpp.Float64":
				
				typeResult = result;
				typeSignature += "d";
			
			case "String":
				
				typeResult = result;
				typeSignature += "s";
			
			case "cpp.ConstCharStar":
				
				typeResult = result;
				typeSignature += "c";
			
			case "Void", "cpp.Void":
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Void).toType ();
					
				} else {
					
					typeResult = result;
					
				}
				
				typeSignature += "v";
				
			default:
				
				if (isCPP) {
					
					typeResult = (macro :cpp.Object).toType ();
					
				} else {
					
					typeResult = (macro :Dynamic).toType ();
					
				}
				
				typeSignature += "o";
			
		}
		
		var typeString = "";
		
		if (typeArgs.length == 0) {
			
			typeString = "Void->";
			
		} else {
			
			for (arg in typeArgs) {
				
				typeString += arg.t.toString () + "->";
				
			}
			
		}
		
		typeString += typeResult.toString ();
		
		return { args: typeArgs, result: typeResult, string: typeString, signature: typeSignature,  };
		
	}
	
	
}


#end