package lime.tools;

@:forward
abstract WindowData({
	@:optional var width:Int;
	@:optional var height:Int;
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var background:Null<Int>;
	@:optional var parameters:String;
	@:optional var fps:Int;
	@:optional var hardware:Bool;
	@:optional var display:Int;
	@:optional var resizable:Bool;
	@:optional var borderless:Bool;
	@:optional var vsync:Bool;
	@:optional var fullscreen:Bool;
	@:optional var allowHighDPI:Bool;
	@:optional var alwaysOnTop:Bool;
	@:optional var antialiasing:Int;
	@:optional var orientation:Orientation;
	@:optional var allowShaders:Bool;
	@:optional var requireShaders:Bool;
	@:optional var depthBuffer:Bool;
	@:optional var stencilBuffer:Bool;
	@:optional var title:String;
	#if (js && html5)
	@:optional var element:js.html.Element;
	#end
	@:optional var colorDepth:Int;
	@:optional var minimized:Bool;
	@:optional var maximized:Bool;
	@:optional var hidden:Bool;
}) from Dynamic
{
	@:noCompletion
	public static var expectedFields:WindowData = {
		width: 0,
		height: 0,
		x: 0.0,
		y: 0.0,
		background: 0,
		parameters: "",
		fps: 0,
		hardware: false,
		display: 0,
		resizable: false,
		borderless: false,
		vsync: false,
		fullscreen: false,
		allowHighDPI: false,
		alwaysOnTop: false,
		antialiasing: 0,
		orientation: Orientation.AUTO,
		allowShaders: false,
		requireShaders: false,
		depthBuffer: false,
		stencilBuffer: false,
		title: "",
		#if (js && html5)
		element: null,
		#end
		colorDepth: 0,
		minimized: false,
		maximized: false,
		hidden: false
	};
}
