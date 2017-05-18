package lime.project;


class Haxelib {
	
	
	public var name:String;
	public var version:String;
	
	
	public function new (name:String, version:String = "") {
		
		this.name = name;
		this.version = version;
		
	}
	
	
	public function clone ():Haxelib {
		
		var haxelib = new Haxelib (name, version);
		return haxelib;
		
	}
	
	
	public function versionMatches (other:String):Bool {
		
		if (version == "" || version == null) return true;
		if (other == "" || other == null) return false;
		
		var filter = version;
		filter = StringTools.replace (filter, ".", "\\.");
		filter = StringTools.replace (filter, "*", ".*");
		
		var regexp = new EReg ("^" + filter, "i");
		
		return regexp.match (other);
		
	}
	
	
}