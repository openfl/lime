package lime.text;


import lime.system.System;

@:access(lime.text.Font)


class TextEngine {
	
	
	public var direction (default, null):TextDirection;
	public var language (default, null):String;
	public var script (default, null):TextScript;
	
	#if (cpp || neko || nodejs)
	private var __handle:Dynamic;
	#end
	
	
	public function new (direction:TextDirection = LEFT_TO_RIGHT, script:TextScript = COMMON, language:String = "") {
		
		this.direction = direction;
		this.script = script;
		this.language = language;
		
		#if (cpp || neko || nodejs)
		__handle = lime_text_engine_create (direction, script, language);
		#end
		
		this.direction = direction;
		
	}
	
	
	public function layout (font:Font, size:Int, text:String):Array<PosInfo> {
		
		#if (cpp || neko || nodejs)
		
		if (font.__handle == null) throw "Uninitialized font handle.";
		return lime_text_engine_layout (__handle, font.__handle, size, text);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_text_engine_create = System.load ("lime", "lime_text_engine_create", 3);
	private static var lime_text_engine_layout = System.load ("lime", "lime_text_engine_layout", 4);
	#end
	
	
}


typedef Point = {
	
	var x:Float;
	var y:Float;
	
};


typedef PosInfo = {
	
	var codepoint:UInt;
	var advance:Point;
	var offset:Point;
	
};