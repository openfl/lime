package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if (!lime_webgl || doc_gen)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
typedef GLContextAttributes =
{
	alpha:Bool,
	depth:Bool,
	stencil:Bool,
	antialias:Bool,
	premultipliedAlpha:Bool,
	preserveDrawingBuffer:Bool
}
#else
typedef GLContextAttributes = js.html.webgl.ContextAttributes;
#end
#end
