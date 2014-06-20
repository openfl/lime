package lime.graphics;
#if js
typedef GLActiveInfo = js.html.webgl.ActiveInfo;
#else


typedef GLActiveInfo = {
	
	size:Int,
	type:Int,
	name:String
	
}


#end