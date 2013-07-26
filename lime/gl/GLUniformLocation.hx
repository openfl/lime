package lime.gl;

#if lime_html5 

    typedef GLUniformLocation = js.html.webgl.UniformLocation;
    
#else //lime_html5

    typedef GLUniformLocation = Dynamic;

#end //lime_native

