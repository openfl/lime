package project;


import haxe.io.Path;


class Library {
	
	
	public var embed:Null<Bool>;
	public var name:String;
	public var sourcePath:String;
	public var type:String;
	
	
	public function new (sourcePath:String, name:String = "", type:String = null, embed:Null<Bool> = null) {
		
		this.sourcePath = sourcePath;
		
		if (name == "") {
			
			this.name = Path.withoutDirectory (Path.withoutExtension (sourcePath));
			
		} else {
			
			this.name = name;
			
		}
		
		this.type = type;
		this.embed = embed;
		
	}
	
	
	public function clone ():Library {
		
		return new Library (sourcePath, name, type, embed);
		
	}
	
	
}