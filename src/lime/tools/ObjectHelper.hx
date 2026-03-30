package lime.tools;

class ObjectHelper
{
	public static function formatForDisplay(object:Dynamic):String
	{
		var keys = Reflect.fields(object);
		keys.sort(Reflect.compare);
		var lines = [];
		for (key in keys)
		{
			lines.push('${key}: ${Reflect.field(object, key)}');
		}
		return lines.join("\n");
	}

	public static function formatJson(obj:Dynamic, indent:Int = 2):String
	{
		return prettyJson(obj, 0, indent);
	}

	private static function objectToString(value:Dynamic):String
	{
		if (value == null) return "null";
		if (Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.string(value);
		if (Std.isOfType(value, String)) return '"' + StringTools.replace(value, '"', '\\"') + '"';

		// Handle enums
		var e = Type.getEnum(value);
		if (e != null) return Type.enumConstructor(value);

		// Handle arrays
		if (Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			return "[" + arr.map(objectToString).join(", ") + "]";
		}

		// Handle objects/maps recursively
		var fields = Reflect.fields(value);
		if (fields.length > 0)
		{
			var pairs = fields.map(function(f)
			{
				return f + ": " + objectToString(Reflect.field(value, f));
			});
			return "{" + pairs.join(", ") + "}";
		}

		return "<unknown>";
	}

	private static function prettyJson(value:Dynamic, level:Int, indent:Int):String
	{
		var isOfType = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end;
		var pad = StringTools.lpad("", " ", level * indent);
		var nextPad = StringTools.lpad("", " ", (level + 1) * indent);

		// Primitive types
		if (value == null) return "null";
		if (isOfType(value, Bool) || isOfType(value, Int) || isOfType(value, Float)) return Std.string(value);
		if (isOfType(value, String)) return '"' + StringTools.replace(value, '"', '\\"') + '"';

		// Enums
		var e = Type.getEnum(value);
		if (e != null) return '"' + Type.enumConstructor(value) + '"';

		// Arrays
		if (isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			var items = arr.map(function(v) return prettyJson(v, level + 1, indent));
			return "[\n" + nextPad + items.join(",\n" + nextPad) + "\n" + pad + "]";
		}

		// Objects
		var fields = Reflect.fields(value);
		fields.sort(Reflect.compare);
		if (fields.length > 0)
		{
			var pairs = fields.map(function(f)
			{
				var v = Reflect.field(value, f);
				return '"' + f + '": ' + prettyJson(v, level + 1, indent);
			});
			return "{\n" + nextPad + pairs.join(",\n" + nextPad) + "\n" + pad + "}";
		}

		return '"<unknown>"';
	}
}
