package lime.project;


import sys.FileSystem;


class NDLL {
	
	
	public var extensionPath:String;
	public var haxelib:Haxelib;
	public var name:String;
	public var path:String;
	public var registerStatics:Bool;
	public var subdirectory:String;
	public var type:NDLLType;
	
	
	public function new (name:String, haxelib:Haxelib = null, type:NDLLType = null, registerStatics:Bool = true) {
		
		this.name = name;
		this.haxelib = haxelib;
		this.type = type == null ? NDLLType.AUTO : type;
		this.registerStatics = registerStatics;
		
	}
	
	
	public function clone ():NDLL {
		
		var ndll = new NDLL (name, haxelib, type, registerStatics);
		ndll.path = path;
		ndll.extensionPath = extensionPath;
		ndll.subdirectory = subdirectory;
		return ndll;
		
	}
	
	
}