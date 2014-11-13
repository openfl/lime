package lime.graphics.opengl; #if (!js || !html5)


typedef GLActiveInfo = {
	
	size:Int,
	type:Int,
	name:String
	
}


#else
typedef GLActiveInfo = js.html.webgl.ActiveInfo;
#end