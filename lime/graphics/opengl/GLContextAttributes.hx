package lime.graphics.opengl;
#if js
typedef GLContextAttributes = js.html.webgl.ContextAttributes;
#else


typedef GLContextAttributes = {
	
	alpha:Bool, 
	depth:Bool,
	stencil:Bool,
	antialias:Bool,
	premultipliedAlpha:Bool,
	preserveDrawingBuffer:Bool
	
}


#end