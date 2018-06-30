package lime.graphics;


#if (js && html5)
import js.html.Element;
#end


typedef RenderContextAttributes = {
	
	@:optional var antialiasing:Int;
	@:optional var background:Null<Int>;
	@:optional var colorDepth:Int;
	@:optional var depth:Bool;
	@:optional var element:#if (js && html5 && !doc_gen) js.html.Element #else Dynamic #end;
	@:optional var hardware:Bool;
	@:optional var stencil:Bool;
	@:optional var type:RenderContextType;
	@:optional var vsync:Bool;
	
}