package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_draw_buffers")
@:noCompletion extern class WEBGL_draw_buffers
{
	public var COLOR_ATTACHMENT0_WEBGL:Int;
	public var COLOR_ATTACHMENT1_WEBGL:Int;
	public var COLOR_ATTACHMENT2_WEBGL:Int;
	public var COLOR_ATTACHMENT3_WEBGL:Int;
	public var COLOR_ATTACHMENT4_WEBGL:Int;
	public var COLOR_ATTACHMENT5_WEBGL:Int;
	public var COLOR_ATTACHMENT6_WEBGL:Int;
	public var COLOR_ATTACHMENT7_WEBGL:Int;
	public var COLOR_ATTACHMENT8_WEBGL:Int;
	public var COLOR_ATTACHMENT9_WEBGL:Int;
	public var COLOR_ATTACHMENT10_WEBGL:Int;
	public var COLOR_ATTACHMENT11_WEBGL:Int;
	public var COLOR_ATTACHMENT12_WEBGL:Int;
	public var COLOR_ATTACHMENT13_WEBGL:Int;
	public var COLOR_ATTACHMENT14_WEBGL:Int;
	public var COLOR_ATTACHMENT15_WEBGL:Int;
	public var DRAW_BUFFER0_WEBGL:Int;
	public var DRAW_BUFFER1_WEBGL:Int;
	public var DRAW_BUFFER2_WEBGL:Int;
	public var DRAW_BUFFER3_WEBGL:Int;
	public var DRAW_BUFFER4_WEBGL:Int;
	public var DRAW_BUFFER5_WEBGL:Int;
	public var DRAW_BUFFER6_WEBGL:Int;
	public var DRAW_BUFFER7_WEBGL:Int;
	public var DRAW_BUFFER8_WEBGL:Int;
	public var DRAW_BUFFER9_WEBGL:Int;
	public var DRAW_BUFFER10_WEBGL:Int;
	public var DRAW_BUFFER11_WEBGL:Int;
	public var DRAW_BUFFER12_WEBGL:Int;
	public var DRAW_BUFFER13_WEBGL:Int;
	public var DRAW_BUFFER14_WEBGL:Int;
	public var DRAW_BUFFER15_WEBGL:Int;
	public var MAX_COLOR_ATTACHMENTS_WEBGL:Int;
	public var MAX_DRAW_BUFFERS_WEBGL:Int;
	public function drawBuffersWEBGL(buffers:Array<Int>):Void;
}
#end
