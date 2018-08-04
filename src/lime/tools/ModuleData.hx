package lime.tools;


import hxp.ArrayHelper;


class ModuleData {


	public var classNames:Array<String>;
	public var excludeTypes:Array<String>;
	public var haxeflags:Array<String>;
	public var includeTypes:Array<String>;
	public var name:String;


	public function new (name:String) {

		this.name = name;
		classNames = [];
		excludeTypes = [];
		haxeflags = [];
		includeTypes = [];

	}


	public function clone ():ModuleData {

		var copy = new ModuleData (name);
		copy.classNames = classNames.copy ();
		copy.excludeTypes = excludeTypes.copy ();
		copy.haxeflags = haxeflags.copy ();
		copy.includeTypes = includeTypes.copy ();
		return copy;

	}


	public function merge (other:ModuleData):Bool {

		if (other.name == name) {

			classNames = ArrayHelper.concatUnique (classNames, other.classNames);
			excludeTypes = ArrayHelper.concatUnique (excludeTypes, other.excludeTypes);
			haxeflags = ArrayHelper.concatUnique (haxeflags, other.haxeflags);
			includeTypes = ArrayHelper.concatUnique (includeTypes, other.includeTypes);
			return true;

		}

		return false;

	}


}