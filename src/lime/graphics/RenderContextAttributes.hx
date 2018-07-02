package lime.graphics;


typedef RenderContextAttributes = {
	
	@:optional var antialiasing:Int;
	@:optional var background:Null<Int>;
	@:optional var colorDepth:Int;
	@:optional var depth:Bool;
	@:optional var hardware:Bool;
	@:optional var stencil:Bool;
	@:optional var type:RenderContextType;
	@:optional var version:String;
	@:optional var vsync:Bool;
	
}