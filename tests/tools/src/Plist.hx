/**
	Reads a property list, such as Info.plist, into Haxe values: a `<dict>` is a
	`Map<String, Dynamic>`, an `<array>` an `Array<Dynamic>`, `<string>` a `String`, and
	`<true/>` and `<false/>` are Bools. It reads the file as strict XML and throws where the
	file is not a property list, as Xcode refuses one.
**/
class Plist
{
	public static function parse(text:String):Map<String, Dynamic>
	{
		var root = PlatformFixture.xml(text).firstElement();

		if (root == null || root.nodeName != "plist") throw "The root element is not <plist>";

		var values = [for (element in root.elements()) element];

		if (values.length != 1 || values[0].nodeName != "dict") throw "<plist> does not hold one <dict>";

		return readDict(values[0]);
	}

	private static function read(element:Xml):Dynamic
	{
		return switch (element.nodeName)
		{
			case "dict": readDict(element);
			case "array": [for (child in element.elements()) read(child)];
			case "string": text(element);
			case "integer": Std.parseInt(text(element));
			case "real": Std.parseFloat(text(element));
			case "true": true;
			case "false": false;
			default: throw "<" + element.nodeName + "> is not a property list value";
		}
	}

	private static function readDict(element:Xml):Map<String, Dynamic>
	{
		var dict = new Map<String, Dynamic>();
		var key:String = null;

		for (child in element.elements())
		{
			if (key == null)
			{
				if (child.nodeName != "key") throw "<" + child.nodeName + "> is where a <key> belongs";

				key = text(child);

				if (dict.exists(key)) throw "The key \"" + key + "\" is given twice";
			}
			else
			{
				if (child.nodeName == "key") throw "The key \"" + key + "\" has no value";

				dict.set(key, read(child));
				key = null;
			}
		}

		if (key != null) throw "The key \"" + key + "\" has no value";

		return dict;
	}

	private static function text(element:Xml):String
	{
		var buffer = new StringBuf();

		for (child in element)
		{
			if (child.nodeType == Xml.PCData || child.nodeType == Xml.CData) buffer.add(child.nodeValue);
		}

		return buffer.toString();
	}
}
