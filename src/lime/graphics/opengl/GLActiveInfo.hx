package lime.graphics.opengl; #if (!js || !html5)


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


typedef GLActiveInfo = {
	
	size:Int,
	type:Int,
	name:String
	
}


#else
typedef GLActiveInfo = js.html.webgl.ActiveInfo;
#end