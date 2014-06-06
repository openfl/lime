package lime.app;


typedef Config = {
	
	@:optional var antialiasing:Int;
	@:optional var borderless:Bool;
	@:optional var depthBuffer:Bool;
	@:optional var fps:Int;
	@:optional var fullscreen:Bool;
	@:optional var height:Int;
	@:optional var orientation:String;
	@:optional var resizable:Bool;
	@:optional var stencilBuffer:Bool;
	@:optional var title:String;
	@:optional var vsync:Bool;
	@:optional var width:Int;
	
}