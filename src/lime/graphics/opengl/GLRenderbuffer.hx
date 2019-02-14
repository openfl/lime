package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if ((lime_opengl || lime_opengles) && !doc_gen)
import lime.graphics.opengl.GL;

@:forward(id)
abstract GLRenderbuffer(GLObject) from GLObject to GLObject
{
	@:from private static function fromInt(id:Int):GLRenderbuffer
	{
		return GLObject.fromInt(RENDERBUFFER, id);
	}
}
#elseif (lime_webgl && !doc_gen)
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else
typedef GLRenderbuffer = Dynamic;
#end
#end
