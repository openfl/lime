package lime.tools;

class Dependency
{
	// TODO: Is "forceLoad" the best name? Implement "whole-archive" on GCC
	public var embed:Bool;
	public var forceLoad:Bool;
	public var name:String;
	public var path:String;

	public function new(name:String, path:String)
	{
		this.name = name;
		this.path = path;
	}

	public function clone():Dependency
	{
		var dependency = new Dependency(name, path);
		dependency.embed = embed;
		dependency.forceLoad = forceLoad;
		return dependency;
	}
}
