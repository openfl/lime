package lime.app;


typedef Config = {
	
	@:optional var antialiasing:Int;
	#if (js && html5)
	@:optional var assetsPrefix:String;
	#end
	@:optional var background:Null<Int>;
	@:optional var borderless:Bool;
	@:optional var company:String;
	@:optional var depthBuffer:Bool;
	#if (js && html5)
	@:optional var element:#if (haxe_ver >= "3.2") js.html.Element #else js.html.HtmlElement #end;
	#end
	@:optional var file:String;
	@:optional var fps:Int;
	@:optional var fullscreen:Bool;
	@:optional var hardware:Bool;
	@:optional var height:Int;
	@:optional var orientation:String;
	@:optional var packageName:String;
	@:optional var resizable:Bool;
	@:optional var stencilBuffer:Bool;
	@:optional var title:String;
	@:optional var version:String;
	@:optional var vsync:Bool;
	@:optional var width:Int;
	
}
