package lime.graphics.opengl; #if (!js || !html5)


typedef GLShaderPrecisionFormat = {
	
	rangeMin:Int,
	rangeMax:Int,
	precision:Int
	
};


#else
typedef GLShaderPrecisionFormat = js.html.webgl.ShaderPrecisionFormat;
#end