package lime.graphics.opengl; #if (!js || !html5 || display)


typedef GLShaderPrecisionFormat = {
	
	rangeMin:Int,
	rangeMax:Int,
	precision:Int
	
};


#else
typedef GLShaderPrecisionFormat = js.html.webgl.ShaderPrecisionFormat;
#end