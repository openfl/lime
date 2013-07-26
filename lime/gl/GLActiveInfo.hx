package lime.gl;

#if lime_html5

    typedef GLActiveInfo = js.html.webgl.ActiveInfo;

#else

	typedef GLActiveInfo = {
		
		size : Int,
		type : Int,
		name : String,
		
	};

#end //lime_html5