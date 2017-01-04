package lime.tools.helpers;

// https://groups.google.com/d/msg/haxelang/N03kf5WSrTU/KU8nmsaqfIIJ
class GUID {
	
	inline public static function randomIntegerWithinRange (min:Int, max:Int):Int {
		
		return Math.floor(Math.random() * (1 + max - min) + min);
		
	}
	
	public static function createRandomIdentifier (length:Int, radix:Int = 61):String {
		
		var characters = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
		var id:Array<String> = new Array<String> ();
		radix = (radix > 61) ? 61 : radix;
		
		while (length-- > 0) {
			
			id.push (characters[GUID.randomIntegerWithinRange (0, radix)]);
		}
		
		return id.join('');
	}
	
	public static function uuid ():String {
		
		var specialChars = ['8', '9', 'A', 'B'];
		
		
		return "{" + GUID.createRandomIdentifier (8, 15) + '-' + 
			GUID.createRandomIdentifier (4, 15) + '-4' + 
			GUID.createRandomIdentifier (3, 15) + '-' + 
			specialChars[GUID.randomIntegerWithinRange (0, 3)] + 
			GUID.createRandomIdentifier (3, 15) + '-' + 
			GUID.createRandomIdentifier (12, 15) +
			"}";
		
	}
	
}