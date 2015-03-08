package lime.text;


import lime.system.System;

@:access(lime.text.Font)


class TextLayout {
	
	
	public var direction(default, null):TextDirection;
	
	#if (cpp || neko || nodejs)
	public var handle:Dynamic;
	#end
	
	
	public function new (direction:TextDirection, script:TextScript, language:String) {
		
		#if (cpp || neko || nodejs)
		handle = lime_text_create (direction, script, language);
		#end
		
		this.direction = direction;
		
	}
	
	
	public function fromString (font:Font, size:Int, text:String):Array<PosInfo> {
		
		#if (cpp || neko || nodejs)
		
		if (font.__handle == null) throw "Uninitialized font handle.";
		return lime_text_from_string (handle, font.__handle, size, text);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	#if (cpp || neko || nodejs)
	private static var lime_text_create = System.load ("lime", "lime_text_create", 3);
	private static var lime_text_from_string = System.load ("lime", "lime_text_from_string", 4);
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