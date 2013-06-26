package lime.gl;


#if lime_native

    typedef GLContextAttributes = {
    	
    	alpha:Bool, 
    	depth:Bool,
    	stencil:Bool,
    	antialias:Bool,
    	premultipliedAlpha:Bool,
    	preserveDrawingBuffer:Bool,
    	
    };

#end //lime_native

#if lime_html5

    typedef GLContextAttributes = js.html.webgl.ContextAttributes;

#end //lime_html5