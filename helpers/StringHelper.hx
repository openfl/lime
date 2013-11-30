package helpers;


#if (flash || openfl || nme)
import flash.utils.ByteArray;
#end
import haxe.crypto.BaseCode;
import haxe.io.Bytes;


class StringHelper {
	
	
	private static var seedNumber = 0;
	private static var base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var base64Encoder:BaseCode;
	private static var usedFlatNames = new Map <String, String> ();
	private static var uuidChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	
	
	#if (flash || openfl || nme)
	
	public static function base64Decode (base64:String):ByteArray {
		
		base64 = StringTools.trim (base64);
		base64 = StringTools.replace (base64, "=", "");
		
		if (base64Encoder == null) {
			
			base64Encoder = new BaseCode (Bytes.ofString (base64Chars));
			
		}
		
		var bytes = base64Encoder.decodeBytes (Bytes.ofString (base64));
		return ByteArray.fromBytes (bytes);
		
	}
	
	
	public static function base64Encode (bytes:ByteArray):String {
		
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
	
	#else
	
	public static function base64Decode (base64:String):haxe.io.Bytes {
		
		return null;
		
	}
	
	
	public static function base64Encode (bytes:haxe.io.Bytes):String {
		
		return null;
		
	}
	
	#end
	
	
	public static function formatArray (array:Array <Dynamic>):String {
		
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
		
		var variableName = "";
		var lastWasUpperCase = false;
		
		for (i in 0...name.length) {
			
			var char = name.charAt (i);
			
			if (char == char.toUpperCase () && i > 0) {
				
				if (lastWasUpperCase) {
					
					if (i == name.length - 1 || name.charAt (i + 1) == name.charAt (i + 1).toUpperCase ()) {
						
						variableName += char;
						
					} else {
						
						variableName += "_" + char;
						
					}
					
				} else {
					
					variableName += "_" + char;
					
				}
				
				lastWasUpperCase = true;
				
			} else {
				
				variableName += char.toUpperCase ();
				lastWasUpperCase = false;
				
			}
			
		}
		
		return variableName;
		
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
	
	
	public static function underline (string:String, character = "="):String {
		
		return string + "\n" + StringTools.lpad ("", character, string.length);
		
	}
		

}