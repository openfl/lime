package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if ((lime_opengl || lime_opengles) && !doc_gen)
import lime.graphics.opengl.GL;

@:forward(id)
abstract GLBuffer(GLObject) from GLObject to GLObject
{
	@:from private static function fromInt(id:Int):GLBuffer
	{
		return GLObject.fromInt(BUFFER, id);
	}
}
#elseif (lime_webgl && !doc_gen)
typedef GLBuffer = js.html.webgl.Buffer;
#else
typedef GLBuffer = Dynamic;
#end
#end
