package lime.tools;

import hxp.*;

class ModuleData
{
	public var classNames:Array<String>;
	public var excludeTypes:Array<String>;
	public var haxeflags:Array<String>;
	public var includeTypes:Array<String>;
	public var name:String;

	public function new(name:String)
	{
		this.name = name;
		classNames = [];
		excludeTypes = [];
		haxeflags = [];
		includeTypes = [];
	}

	public function clone():ModuleData
	{
		var copy = new ModuleData(name);
		copy.classNames = classNames.copy();
		copy.excludeTypes = excludeTypes.copy();
		copy.haxeflags = haxeflags.copy();
		copy.includeTypes = includeTypes.copy();
		return copy;
	}

	public function merge(other:ModuleData):Bool
	{
		if (other.name == name)
		{
			classNames = ArrayTools.concatUnique(classNames, other.classNames);
			excludeTypes = ArrayTools.concatUnique(excludeTypes, other.excludeTypes);
			haxeflags = ArrayTools.concatUnique(haxeflags, other.haxeflags);
			includeTypes = ArrayTools.concatUnique(includeTypes, other.includeTypes);
			return true;
		}

		return false;
	}
}
