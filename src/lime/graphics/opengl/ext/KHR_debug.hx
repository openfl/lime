package lime.graphics.opengl.ext;

@:keep
@:noCompletion class KHR_debug
{
	public var DEBUG_OUTPUT_SYNCHRONOUS = 0x8242;
	public var DEBUG_NEXT_LOGGED_MESSAGE_LENGTH = 0x8243;
	public var DEBUG_CALLBACK_FUNCTION = 0x8244;
	public var DEBUG_CALLBACK_USER_PARAM = 0x8245;
	public var DEBUG_SOURCE_API = 0x8246;
	public var DEBUG_SOURCE_WINDOW_SYSTEM = 0x8247;
	public var DEBUG_SOURCE_SHADER_COMPILER = 0x8248;
	public var DEBUG_SOURCE_THIRD_PARTY = 0x8249;
	public var DEBUG_SOURCE_APPLICATION = 0x824A;
	public var DEBUG_SOURCE_OTHER = 0x824B;
	public var DEBUG_TYPE_ERROR = 0x824C;
	public var DEBUG_TYPE_DEPRECATED_BEHAVIOR = 0x824D;
	public var DEBUG_TYPE_UNDEFINED_BEHAVIOR = 0x824E;
	public var DEBUG_TYPE_PORTABILITY = 0x824F;
	public var DEBUG_TYPE_PERFORMANCE = 0x8250;
	public var DEBUG_TYPE_OTHER = 0x8251;
	public var DEBUG_TYPE_MARKER = 0x8268;
	public var DEBUG_TYPE_PUSH_GROUP = 0x8269;
	public var DEBUG_TYPE_POP_GROUP = 0x826A;
	public var DEBUG_SEVERITY_NOTIFICATION = 0x826B;
	public var MAX_DEBUG_GROUP_STACK_DEPTH = 0x826C;
	public var DEBUG_GROUP_STACK_DEPTH = 0x826D;
	public var BUFFER = 0x82E0;
	public var SHADER = 0x82E1;
	public var PROGRAM = 0x82E2;
	public var QUERY = 0x82E3;
	public var SAMPLER = 0x82E6;
	public var MAX_LABEL_LENGTH = 0x82E8;
	public var MAX_DEBUG_MESSAGE_LENGTH = 0x9143;
	public var MAX_DEBUG_LOGGED_MESSAGES = 0x9144;
	public var DEBUG_LOGGED_MESSAGES = 0x9145;
	public var DEBUG_SEVERITY_HIGH = 0x9146;
	public var DEBUG_SEVERITY_MEDIUM = 0x9147;
	public var DEBUG_SEVERITY_LOW = 0x9148;
	public var DEBUG_OUTPUT = 0x92E0;
	public var CONTEXT_FLAG_DEBUG_BIT = 0x00000002;
	public var STACK_OVERFLOW = 0x0503;
	public var STACK_UNDERFLOW = 0x0504;

	@:noCompletion private function new() {}

	// public function debugMessageControl (source:Int, type:Int, severity:Int, count:Int, ids:Array<Int>, enabled:Bool):Void {}
	// public function debugMessageInsert (source:Int, type:Int, id:Int, severity:Int, message:String):Void {}
	// public function debugMessageCallback (callback:Dynamic, userParam:Dynamic):Void;
	// public function getDebugMessageLog (count:Int, sources:Array<Int>, types:Array<Int>, ids:Array<Int>, severities:Array<Int>, lengths:Array<Int>):String {}
	// public function pushDebugGroup (source:Int, id:Int, message:String):Void {}
	// public function popDebugGroup ():Void {}
	// public function objectLabel (identifier:Int, name:Int, label:String):Void {}
	// public function getObjectLabel (identifier:Int, name:Int):String {}
	// public function objectPtrLabel (ptr:Dynamic, label:String):Void {}
	// public function getObjectPtrLabel (ptr:Dynamic):String {}
	// public function getPointerv (pname:Int, params:Array<Dynamic>):Void {}
}
