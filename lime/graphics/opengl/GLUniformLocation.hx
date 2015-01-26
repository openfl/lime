package lime.graphics.opengl; #if (!js || !html5 || display)


typedef GLUniformLocation = Int;


#else
typedef GLUniformLocation = js.html.webgl.UniformLocation;
#end