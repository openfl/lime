package lime.graphics.opengl; #if (!js || !html5 || display)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


typedef GLShaderPrecisionFormat = {
	
	rangeMin:Int,
	rangeMax:Int,
	precision:Int
	
};


#else
typedef GLShaderPrecisionFormat = js.html.webgl.ShaderPrecisionFormat;
#end