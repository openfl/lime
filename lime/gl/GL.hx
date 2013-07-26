package lime.gl;

#if lime_html5
    typedef GL = lime.gl.html5.GL;
#else
	typedef GL = lime.gl.native.GL;
#end //lime_html5