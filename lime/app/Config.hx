package lime.app;


import lime.project.MetaData;
import lime.project.WindowData;


typedef Config = {
	
	#if (js && html5)
	@:optional var assetsPrefix:String;
	#end
	@:optional var meta:MetaData;
	@:optional var windows:Array<WindowData>;
	#if (js && html5)
	@:optional var element:#if (haxe_ver >= "3.2") js.html.Element #else js.html.HtmlElement #end;
	#end
	@:optional var file:String;
	
}