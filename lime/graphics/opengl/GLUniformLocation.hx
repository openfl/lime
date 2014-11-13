package lime.graphics.opengl; #if (!js || !html5)


typedef GLUniformLocation = Int;


#else
typedef GLUniformLocation = js.html.webgl.UniformLocation;
#end