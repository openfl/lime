package lime.graphics.opengl; #if !js


typedef GLUniformLocation = Int;


#else
typedef GLUniformLocation = js.html.webgl.UniformLocation;
#end