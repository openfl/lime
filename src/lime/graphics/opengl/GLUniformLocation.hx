package lime.graphics.opengl;

#if (!lime_doc_gen || lime_opengl || lime_opengles || lime_webgl)
#if (!lime_webgl || doc_gen)
typedef GLUniformLocation = Int;
#else
typedef GLUniformLocation = js.html.webgl.UniformLocation;
#end
#end
