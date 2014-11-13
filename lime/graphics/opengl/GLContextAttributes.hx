package lime.graphics.opengl; #if (!js || !html5)


typedef GLContextAttributes = {
	
	alpha:Bool, 
	depth:Bool,
	stencil:Bool,
	antialias:Bool,
	premultipliedAlpha:Bool,
	preserveDrawingBuffer:Bool
	
}


#else
typedef GLContextAttributes = js.html.webgl.ContextAttributes;
#end