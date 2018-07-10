package lime.graphics; #if (lime_doc_gen && lime_canvas) #if (lime_canvas && (lime_doc_gen || !doc_gen))


import js.html.CanvasRenderingContext2D;

@:access(lime.graphics.RenderContext)
@:forward()


abstract Canvas2DRenderContext(CanvasRenderingContext2D) from CanvasRenderingContext2D to CanvasRenderingContext2D {
	
	
	@:from private static function fromRenderContext (context:RenderContext):Canvas2DRenderContext {
		
		return context.canvas2D;
		
	}
	
	
}


#else


@:forward()


abstract Canvas2DRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):Canvas2DRenderContext {
		
		return null;
		
	}
	
	
}


#end
#end