package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if (!lime_webgl || doc_gen)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
typedef GLShaderPrecisionFormat =
{
	rangeMin:Int,
	rangeMax:Int,
	precision:Int
};

#else
typedef GLShaderPrecisionFormat = js.html.webgl.ShaderPrecisionFormat;
#end
#end
