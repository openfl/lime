package lime.gl;

#if lime_native

typedef GLActiveInfo = {
	
	size : Int,
	type : Int,
	name : String,
	
};

#end //lime_native

#if lime_html5

    typedef GLActiveInfo = js.html.webgl.ActiveInfo;
    
#end //lime_html5