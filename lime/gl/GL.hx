package lime.gl;


#if lime_native
    
    typedef GL = lime.gl.native.GL;

#end //lime_native


#if lime_html5

    typedef GL = lime.gl.html5.GL;

#end //lime_html5