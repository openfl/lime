package lime.graphics.opengl; #if !html5


typedef GLUniformLocation = Int;


#else
typedef GLUniformLocation = js.html.webgl.UniformLocation;
#end