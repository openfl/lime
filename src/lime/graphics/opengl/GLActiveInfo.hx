package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if (!lime_webgl || doc_gen)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
typedef GLActiveInfo =
{
	size:Int,
	type:Int,
	name:String
}
#else
typedef GLActiveInfo = js.html.webgl.ActiveInfo;
#end
#end
