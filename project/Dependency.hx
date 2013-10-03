package project;


class Dependency {
	
	
	public var name:String;
	public var path:String;
	
	
	public function new (name:String, path:String) {
		
		this.name = name;
		this.path = path;
		
	}
	
	
	public function clone ():Dependency {
		
		return new Dependency (name, path);
		
	}
	
	
}