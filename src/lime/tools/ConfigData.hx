package lime.tools;

import hxp.*;
#if (haxe_ver >= 4)
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

abstract ConfigData(Dynamic) to Dynamic from Dynamic
{
	private static inline var ARRAY:String = "___array";

	public function new()
	{
		this = {};
	}

	private function addBucket(bucket:String, parent:Dynamic):Dynamic
	{
		if (!Reflect.hasField(parent, bucket))
		{
			log("config data > adding a bucketType " + bucket);
			Reflect.setField(parent, bucket, {});
		}

		return Reflect.field(parent, bucket);
	}

	public function clone():ConfigData
	{
		return ObjectTools.deepCopy(this);
	}

	public function exists(id:String):Bool
	{
		return get(id) != null;
	}

	public function get(id:String):ConfigData
	{
		var tree = id.split(".");
		var current = this;

		for (leaf in tree)
		{
			current = Reflect.field(current, leaf);

			if (current == null)
			{
				return null;
			}
		}

		return current;
	}

	public function getArray(id:String, defaultValue:Array<Dynamic> = null):Array<Dynamic>
	{
		var tree = id.split(".");
		var array:Array<Dynamic> = null;

		var current = this;
		var field = tree.pop();

		for (leaf in tree)
		{
			current = Reflect.field(current, leaf);

			if (current == null)
			{
				break;
			}
		}

		if (current != null)
		{
			array = Reflect.field(current, field + ARRAY);

			if (array == null && Reflect.hasField(current, field))
			{
				array = [Reflect.field(current, field)];
			}
		}

		if (array != null)
		{
			return array;
		}

		if (defaultValue == null)
		{
			defaultValue = [];
		}

		return defaultValue;
	}

	public function getArrayString(id:String, childField:String = null, defaultValue:Array<String> = null):Array<String>
	{
		var array = getArray(id);

		if (array.length > 0)
		{
			var value:Array<String> = [];

			if (childField == null)
			{
				for (item in array)
				{
					value.push(Std.string(item));
				}
			}
			else
			{
				for (item in array)
				{
					value.push(Std.string(Reflect.field(item, childField)));
				}
			}

			return value;
		}

		if (defaultValue == null)
		{
			defaultValue = [];
		}

		return defaultValue;
	}

	public function getBool(id:String, defaultValue:Bool = true):Bool
	{
		if (exists(id))
		{
			return get(id) == "true";
		}

		return defaultValue;
	}

	public function getInt(id:String, defaultValue:Int = 0):Int
	{
		if (exists(id))
		{
			return Std.parseInt(Std.string(get(id)));
		}

		return defaultValue;
	}

	public function getFloat(id:String, defaultValue:Float = 0):Float
	{
		if (exists(id))
		{
			return Std.parseFloat(Std.string(get(id)));
		}

		return defaultValue;
	}

	public function getString(id:String, defaultValue:String = ""):String
	{
		if (exists(id))
		{
			return Std.string(get(id));
		}

		return defaultValue;
	}

	public function getKeyValueArray(id:String, defaultValues:Dynamic = null):Array<{ key:String, value:Dynamic }>
	{
		var values = {};
		if (defaultValues != null)
		{
			ObjectTools.copyFields(defaultValues, values);
		}

		var data = get(id);
		for (key in Reflect.fields(data))
		{
			if (!StringTools.endsWith (key, ARRAY))
			{
				Reflect.setField(values, key, Reflect.field(data, key));
			}
		}

		var pairs:Array<{ key:String, value:Dynamic }> = [];
		for (key in Reflect.fields(values))
		{
			pairs.push({ key: key, value: Reflect.field(values, key) });
		}

		return pairs;
	}

	private function log(v:Dynamic):Void
	{
		if (Log.verbose)
		{
			// Log.println (v);
		}
	}

	public function merge(other:ConfigData):Void
	{
		if (other != null)
		{
			mergeValues(other, this);
		}
	}

	private function mergeValues<T>(source:T, destination:T):Void
	{
		for (field in Reflect.fields(source))
		{
			if (StringTools.endsWith(field, ARRAY))
			{
				continue;
			}

			var doCopy = true;
			var exists = Reflect.hasField(destination, field);
			var typeDest:String = null;

			if (exists)
			{
				var valueSource = Reflect.field(source, field);
				var valueDest = Reflect.field(destination, field);
				var typeSource = Type.typeof(valueSource).getName();
				typeDest = Type.typeof(valueDest).getName();

				// if trying to copy a non object over an object, don't
				if (typeSource != "TObject" && typeDest == "TObject")
				{
					doCopy = false;

					// if (Log.verbose) {
					//
					// Log.println (field + " not merged by preference");
					//
					// }
				}

				if (doCopy && Reflect.field(source, field) != Reflect.field(destination, field) && typeSource != "TObject")
				{
					if (!Reflect.hasField(destination, field + ARRAY))
					{
						Reflect.setField(destination, field + ARRAY, [ObjectTools.deepCopy(Reflect.field(destination, field))]);
					}

					var array:Array<Dynamic> = Reflect.field(destination, field + ARRAY);

					if (Reflect.hasField(source, field + ARRAY))
					{
						array = array.concat(Reflect.field(source, field + ARRAY));
						Reflect.setField(destination, field + ARRAY, array);
					}
					else
					{
						array.push(Reflect.field(source, field));
					}

					Reflect.setField(destination, field, Reflect.field(source, field));
					doCopy = false;
				}
			}

			if (doCopy)
			{
				if (typeDest == "TObject")
				{
					mergeValues(Reflect.field(source, field), Reflect.field(destination, field));
				}
				else
				{
					Reflect.setField(destination, field, Reflect.field(source, field));

					if (Reflect.hasField(source, field + ARRAY))
					{
						Reflect.setField(destination, field + ARRAY, Reflect.field(source, field + ARRAY));
					}
				}
			}
		}
	}

	public function parse(elem:Access, substitute:String->String = null):Void
	{
		var bucket = this;
		var bucketType = "";

		if (StringTools.startsWith(elem.name, "config:"))
		{
			var items = elem.name.split(":");
			bucketType = items[1];
		}

		if (elem.has.type)
		{
			bucketType = elem.att.type;
		}

		if (bucketType != "")
		{
			bucket = addBucket(bucketType, this);
		}

		parseAttributes(elem, bucket, substitute);
		parseChildren(elem, bucket, 0, substitute);

		log("> current config : " + this);
	}

	private function parseAttributes(elem:Access, bucket:Dynamic, substitute:String->String = null):Void
	{
		for (attrName in elem.x.attributes())
		{
			if (attrName != "type")
			{
				var attrValue = elem.x.get(attrName);
				if (substitute != null) attrValue = substitute(attrValue);
				setNode(bucket, attrName, attrValue);
			}
		}
	}

	private function parseChildren(elem:Access, bucket:Dynamic, depth:Int = 0, substitute:String->String = null):Void
	{
		for (child in elem.elements)
		{
			if (child.name != "config")
			{
				// log("config data > child : " + child.name);

				var d = depth + 1;

				var hasChildren = child.x.elements().hasNext();
				var hasAttributes = child.x.attributes().hasNext();

				if (Reflect.hasField(bucket, child.name))
				{
					var array:Array<Dynamic> = Reflect.field(bucket, child.name + ARRAY);
					if (array == null)
					{
						array = [ObjectTools.deepCopy(Reflect.field(bucket, child.name))];
						Reflect.setField(bucket, child.name + ARRAY, array);
					}

					var arrayBucket = {};
					array.push(arrayBucket);

					if (hasAttributes)
					{
						parseAttributes(child, arrayBucket, substitute);
					}

					if (hasChildren)
					{
						parseChildren(child, arrayBucket, d, substitute);
					}

					if (!hasChildren && !hasAttributes)
					{
						parseValue(child, arrayBucket, substitute);
					}
				}

				if (!hasChildren && !hasAttributes)
				{
					parseValue(child, bucket, substitute);
				}
				else
				{
					var childBucket = addBucket(child.name, bucket);

					if (hasAttributes)
					{
						parseAttributes(child, childBucket, substitute);
					}

					if (hasChildren)
					{
						parseChildren(child, childBucket, d, substitute);
					}
				}
			}
		}
	}

	private function parseValue(elem:Access, bucket:Dynamic, substitute:String->String = null):Void
	{
		if (elem.innerHTML != "")
		{
			var value = elem.innerHTML;
			if (substitute != null) value = substitute(value);
			setNode(bucket, elem.name, value);
		}
	}

	public function push(id:String, value:Dynamic, ?unique:Bool = false):Void
	{
		var tree = id.split(".");
		var current = this;
		var field = tree.pop();

		for (leaf in tree)
		{
			if (!Reflect.hasField(current, leaf))
			{
				Reflect.setField(current, leaf, {});
				current = Reflect.field(current, leaf);
			}
			else
			{
				current = Reflect.field(current, leaf);

				if (current == null)
				{
					return;
				}
			}
		}

		if (Reflect.hasField(current, field))
		{
			var array:Array<Dynamic> = Reflect.field(current, field + ARRAY);

			if (array == null)
			{
				array = [ObjectTools.deepCopy(Reflect.field(current, field))];
				Reflect.setField(current, field + ARRAY, array);
			}

			if (!unique || array.indexOf(value) == -1)
			{
				array.push(value);
			}
		}

		Reflect.setField(current, field, value);
	}

	public function set(id:String, value:Dynamic):Void
	{
		var tree = id.split(".");
		var current = this;
		var field = tree.pop();

		for (leaf in tree)
		{
			if (!Reflect.hasField(current, leaf))
			{
				Reflect.setField(current, leaf, {});
				current = Reflect.field(current, leaf);
			}
			else
			{
				current = Reflect.field(current, leaf);

				if (current == null)
				{
					return;
				}
			}
		}

		Reflect.setField(current, field, value);
	}

	private function setNode(bucket:Dynamic, node:String, value:Dynamic):Void
	{
		// log("config data > setting a node " + node + " to " + value + " on " + bucket);

		var doCopy = true;
		var exists = Reflect.hasField(bucket, node);

		if (exists)
		{
			var valueDest = Reflect.field(bucket, node);
			var typeSource = Type.typeof(value).getName();
			var typeDest = Type.typeof(valueDest).getName();

			// trace (node + " / existed in dest as " + typeDest + " / " + typeSource );

			if (typeSource != "TObject" && typeDest == "TObject")
			{
				doCopy = false;
				log(node + " not merged by preference over object");
			}

			if (doCopy)
			{
				if (typeSource != "TObject")
				{
					var array:Array<Dynamic> = Reflect.field(bucket, node + ARRAY);
					if (array == null)
					{
						array = [ObjectTools.deepCopy(Reflect.field(bucket, node))];
						Reflect.setField(bucket, node + ARRAY, array);
					}

					array.push(value);
				}

				Reflect.setField(bucket, node, value);
			}
		}
		else
		{
			Reflect.setField(bucket, node, value);
		}
	}
}
