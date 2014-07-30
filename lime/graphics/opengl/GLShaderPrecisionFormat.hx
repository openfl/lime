package lime.graphics.opengl; #if !js


typedef GLShaderPrecisionFormat = {
	
	rangeMin:Int,
	rangeMax:Int,
	precision:Int
	
};


#else
typedef GLShaderPrecisionFormat = js.html.webgl.ShaderPrecisionFormat;
#end