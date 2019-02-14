package lime.graphics.opengl.ext;

#if (js && html5)
@:keep
@:native("WEBGL_lose_context")
extern @:noCompletion class WEBGL_lose_context
{
	public function loseContext():Void;
	public function restoreContext():Void;
}
#end
