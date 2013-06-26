package lime.gl;

#if lime_native

    typedef GLUniformLocation = Dynamic;

#end //lime_native

#if lime_html5 

    typedef GLUniformLocation = js.html.webgl.UniformLocation;
    
#end //lime_html5