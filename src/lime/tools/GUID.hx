package lime.tools;

import haxe.crypto.Sha1;
import haxe.io.Bytes;
import haxe.crypto.Crc32;

// https://groups.google.com/d/msg/haxelang/N03kf5WSrTU/KU8nmsaqfIIJ
class GUID
{
	inline public static function randomIntegerWithinRange(min:Int, max:Int, ?seeded:Bool = false):Int
	{
		return seeded ? Math.floor(GUID.seededRandom() * (1 + max - min) + min) : Math.floor(Math.random() * (1 + max - min) + min);
	}

	public static function createRandomIdentifier(length:Int, radix:Int = 61, ?seeded:Bool = false):String
	{
		var characters = [
			'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
			'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
			'w', 'x', 'y', 'z'
		];
		var id:Array<String> = new Array<String>();
		radix = (radix > 61) ? 61 : radix;

		while (length-- > 0)
		{
			id.push(characters[GUID.randomIntegerWithinRange(0, radix, seeded)]);
		}

		return id.join('');
	}

	public static function uuid(?seeded:Bool = false):String
	{
		var specialChars = ['8', '9', 'A', 'B'];

		return "{"
			+ GUID.createRandomIdentifier(8, 15, seeded)
			+ '-'
			+ GUID.createRandomIdentifier(4, 15, seeded)
			+ '-4'
			+ GUID.createRandomIdentifier(3, 15, seeded)
			+ '-'
			+ specialChars[GUID.randomIntegerWithinRange(0, 3, seeded)]
			+ GUID.createRandomIdentifier(3, 15, seeded)
			+ '-'
			+ GUID.createRandomIdentifier(12, 15, seeded)
			+ "}";
	}

	private static var seed:Int = 0;

	private static function setSeed(input:String):Int
	{
		var inputBytes = Bytes.ofString(input);
		var hashedBytes = Sha1.make(inputBytes);
		return GUID.seed = Crc32.make(hashedBytes);
	}

	private static function seededRandom():Float
	{
		GUID.seed++;
		var x = Math.sin(GUID.seed) * 10000;
		return x - Math.floor(x);
	}

	public static function seededUuid(seed:String):String
	{
		GUID.setSeed(seed);
		return uuid(true);
	}
}
