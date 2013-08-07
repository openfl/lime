package lime.gl;

#if lime_html5
    typedef GL = lime.gl.html5.GL;
    typedef Ext = lime.gl.html5.Ext;
#else
	typedef GL = lime.gl.native.GL;
	typedef Ext = lime.gl.native.Ext;
#end //lime_html5