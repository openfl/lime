package lime.tools.helpers;


import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import lime.project.Haxelib;
import lime.project.HXProject;


class StringHelper {
	
	
	private static var seedNumber = 0;
	private static var base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var base64Encoder:BaseCode;
	private static var usedFlatNames = new Map<String, String> ();
	private static var uuidChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	
	
	public static function base64Decode (base64:String):Bytes {
		
		base64 = StringTools.trim (base64);
		base64 = StringTools.replace (base64, "=", "");
		
		if (base64Encoder == null) {
			
			base64Encoder = new BaseCode (Bytes.ofString (base64Chars));
			
		}
		
		var bytes = base64Encoder.decodeBytes (Bytes.ofString (base64));
		return bytes;
		
	}
	
	
	public static function base64Encode (bytes:Bytes):String {
		
		var extension = switch (bytes.length % 3) {
			
			case 1: "==";
			case 2: "=";
			default: "";
			
		}
		
		if (base64Encoder == null) {
			
			base64Encoder = new BaseCode (Bytes.ofString (base64Chars));
			
		}
		
		return base64Encoder.encodeBytes (bytes).toString () + extension;
		
	}
	
	
	public static function filter (text:String, include:Array<String> = null, exclude:Array<String> = null):Bool {
		
		if (include == null) {
			
			include = [ "*" ];
			
		}
		
		if (exclude == null) {
			
			exclude = [];
			
		}
		
		for (filter in exclude) {
			
			if (filter != "") {

				if(filter == "*") return false;
				if(filter.indexOf("*") == filter.length - 1) {
					if(StringTools.startsWith(text, filter.substr(0, -1))) return false;
					continue;
				}

				filter = StringTools.replace (filter, ".", "\\.");
				filter = StringTools.replace (filter, "*", ".*");
				
				var regexp = new EReg ("^" + filter + "$", "i");
				
				if (regexp.match (text)) {
					
					return false;
					
				}
				
			}
			
		}
		
		for (filter in include) {
			
			if (filter != "") {

				if(filter == "*") return true;
				if(filter.indexOf("*") == filter.length - 1) {
					if(StringTools.startsWith(text, filter.substr(0, -1))) return true;
					continue;
				}

				filter = StringTools.replace (filter, ".", "\\.");
				filter = StringTools.replace (filter, "*", ".*");
				
				var regexp = new EReg ("^" + filter, "i");
				
				if (regexp.match (text)) {
					
					return true;
					
				}
				
			}
			
		}
		
		return false;
		
	}
	
	
	public static function formatArray (array:Array<Dynamic>):String {
		
		var output = "[ ";
		
		for (i in 0...array.length) {
			
			output += array[i];
			
			if (i < array.length - 1) {
				
				output += ", ";
				
			} else {
				
				output += " ";
				
			}
			
		}
		
		output += "]";
		
		return output;
		
	}
	
	
	public static function formatEnum (value:Dynamic):String {
			
		return Type.getEnumName (Type.getEnum (value)) + "." + value;
		
	}
	
	
	public static function formatUppercaseVariable (name:String):String {
		
		var isAlpha = ~/[A-Z0-9]/i;
		var variableName = "";
		var lastWasUpperCase = false;
		var lastWasAlpha = true;
		
		for (i in 0...name.length) {
			
			var char = name.charAt (i);
			
			if (!isAlpha.match (char)) {
				
				variableName += "_";
				lastWasUpperCase = false;
				lastWasAlpha = false;
				
			} else {
				
				if (char == char.toUpperCase () && i > 0) {
					
					if (lastWasUpperCase) {
						
						if (i == name.length - 1 || name.charAt (i + 1) == name.charAt (i + 1).toUpperCase ()) {
							
							variableName += char;
							
						} else {
							
							variableName += "_" + char;
							
						}
						
					} else if (lastWasAlpha) {
						
						variableName += "_" + char;
						
					} else {
						
						variableName += char;
						
					}
					
					lastWasUpperCase = true;
					
				} else {
					
					variableName += char.toUpperCase ();
					lastWasUpperCase = i == 0 && char == char.toUpperCase ();
					
				}
				
				lastWasAlpha = true;
				
			}
			
		}
		
		return variableName;
		
	}
	
	
	public static function generateHashCode (value:String):Int {
		
		var hash = 5381;
		var length = value.length;
		
		for (i in 0...value.length) {
			
			hash = ((hash << 5) + hash) + value.charCodeAt (i);
			
		}
		
		return hash;
		
	}
	
	
	public static function generateUUID (length:Int, radix:Null<Int> = null, seed:Null<Int> = null):String {
		
		var chars = uuidChars.split ("");
		
		if (radix == null || radix > chars.length) {
			
			radix = chars.length;
			
		} else if (radix < 2) {
			
			radix = 2;
			
		}
		
		if (seed == null) {
			
			seed = Math.floor (Math.random () * 2147483647.0);
			
		}
		
		var uuid = [];
		var seedValue:Int = Math.round (Math.abs (seed));
		
		for (i in 0...length) {
			
			seedValue = Std.int ((seedValue * 16807.0) % 2147483647.0);
			uuid[i] = chars[0 | Std.int ((seedValue / 2147483647.0) * radix)];
			
		}
		
		return uuid.join ("");
		
	}
	
	
	
	public static function getFlatName (name:String):String {
		
		var chars = name.toLowerCase ();
		var flatName = "";
		
		for (i in 0...chars.length) {
			
			var code = chars.charCodeAt (i);
			
			if ((i > 0 && code >= "0".charCodeAt (0) && code <= "9".charCodeAt (0)) || (code >= "a".charCodeAt (0) && code <= "z".charCodeAt (0)) || (code == "_".charCodeAt (0))) {
				
				flatName += chars.charAt (i);
				
			} else {
				
				flatName += "_";
				
			}
			
		}
		
		if (flatName == "") {
			
			flatName = "_";
			
		}
		
		if (flatName.substr (0, 1) == "_") {
			
			flatName = "file" + flatName;
			
		}
		
		while (usedFlatNames.exists (flatName)) {
			
			// Find last digit ...
			var match = ~/(.*?)(\d+)/;
			
			if (match.match (flatName)) {
				
				flatName = match.matched (1) + (Std.parseInt (match.matched (2)) + 1);
				
			} else {
				
				flatName += "1";
				
			}
			
		}
		
		usedFlatNames.set (flatName, "1");
		
		return flatName;
		
	}
	
	
	public static function getUniqueID ():String {
		
		return StringTools.hex (seedNumber++, 8);
		
	}
	
	
	public static function replaceVariable (project:HXProject, string:String):String {
		
		if (string.substr (0, 8) == "haxelib:") {
			
			var path = HaxelibHelper.getPath (new Haxelib (string.substr (8)), true);
			return PathHelper.standardize (path);
			
		} else if (project.defines.exists (string)) {
			
			return project.defines.get (string);
			
		} else if (project.environment != null && project.environment.exists (string)) {
			
			return project.environment.get (string);
			
		} else {
			
			var substring = StringTools.replace (string, " ", "");
			var index, value;
			
			if (substring.indexOf ("==") > -1) {
				
				index = substring.indexOf ("==");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value == substring.substr (index + 2));
				
			} else if (substring.indexOf ("!=") > -1) {
				
				index = substring.indexOf ("!=");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value != substring.substr (index + 2));
				
			} else if (substring.indexOf ("<=") > -1) {
				
				index = substring.indexOf ("<=");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value <= substring.substr (index + 2));
				
			} else if (substring.indexOf ("<") > -1) {
				
				index = substring.indexOf ("<");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value < substring.substr (index + 1));
				
			} else if (substring.indexOf (">=") > -1) {
				
				index = substring.indexOf (">=");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value >= substring.substr (index + 2));
				
			} else if (substring.indexOf (">") > -1) {
				
				index = substring.indexOf (">");
				value = StringHelper.replaceVariable (project, substring.substr (0, index));
				
				return Std.string (value > substring.substr (index + 1));
				
			} else if (substring.indexOf (".") > -1) {
				
				var index = substring.indexOf (".");
				var fieldName = substring.substr (0, index);
				var subField = substring.substr (index + 1);
				
				if (Reflect.hasField (project, fieldName)) {
					
					var field = Reflect.field (project, fieldName);
					
					if (Reflect.hasField (field, subField)) {
						
						return Std.string (Reflect.field (field, subField));
						
					}
					
				}
				
			} else if (substring == "projectDirectory") {
				
				// TODO: Better handling if CWD has changed?
				
				return Std.string (Sys.getCwd ());
				
			}
			
		}
		
		return string;
		
	}
	
	
	public static function underline (string:String, character = "="):String {
		
		return string + "\n" + StringTools.lpad ("", character, string.length);
		
	}
	
	
}