package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if ((lime_opengl || lime_opengles) && !doc_gen)
import lime.graphics.opengl.GL;

@:forward(id)
abstract GLFramebuffer(GLObject) from GLObject to GLObject
{
	@:from private static function fromInt(id:Int):GLFramebuffer
	{
		return GLObject.fromInt(FRAMEBUFFER, id);
	}
}
#elseif (lime_webgl && !doc_gen)
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else
typedef GLFramebuffer = Dynamic;
#end
#end
